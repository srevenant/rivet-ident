defmodule Rivet.Auth.Signin.Local do
  @moduledoc """
  Local login scheme
  """
  alias Rivet.Auth
  use Rivet.Ident
  alias Rivet.Ident.Factor

  @spec signup(String.t(), params :: map()) :: Auth.Domain.result()
  def signup(host, args, type \\ :authed)

  def signup(
        hostname,
        %{"handle" => handle, "password" => secret, "email" => address},
        type
      )
      when is_binary(hostname) do
    case Ident.Email.one([address: address], [:user]) do
      {:ok, %Ident.Email{}} ->
        {:error, %Auth.Domain{error: "A signin already exists for `#{address}`"}}

      _ ->
        handle = Ident.Handle.Lib.gen_good_handle!(handle)
        email = %{address, verified: false}
        input = %{secret, handle, email}

        User.Signup.signup(%Auth.Domain{hostname, input}, type)
        |> Rivet.Auth.Signin.post_signin()
    end
  end

  def signup(_, _, _) do
    {:error,
     %Auth.Domain{log: "Auth signup failed, arguments don't match", error: "Signup Failed"}}
  end

  ##############################################################################
  @spec check(Auth.Domain.t() | String.t(), params :: map()) :: Auth.Domain.result()
  def check(%Auth.Domain{} = auth, %{"handle" => handle, "password" => password}) do
    with {:ok, auth} <- load_user(auth, handle),
         {:ok, user} <- User.Lib.check_user_status(auth.user),
         {:ok, auth} <- load_password_factor(%{auth | user}),
         {:ok, auth} <- valid_user_factor(auth, password),
         do: Rivet.Auth.Signin.post_signin(auth)
  end

  def check(hostname, args = %{"handle" => _, "password" => _}) when is_binary(hostname),
    do: check(%Auth.Domain{hostname: hostname}, args)

  ##############################################################################
  @auth_fail_msg "Unable to sign in. Did you want to sign up instead?"
  @spec load_user(Auth.Domain.t(), handle :: String.t()) :: Auth.Domain.result()
  def load_user(%Auth.Domain{} = auth, handle) do
    if String.contains?(handle, "@") do
      case Ident.Email.one([address: handle], [:user]) do
        {:ok, email} ->
          {:ok, %Auth.Domain{auth | user: email.user}}

        _ ->
          {:error, %Auth.Domain{log: "Cannot find email #{handle}", error: @auth_fail_msg}}
      end
    else
      case Ident.Handle.one([handle: handle], [:user]) do
        {:ok, handle} ->
          {:ok, %Auth.Domain{auth | handle: handle, user: handle.user}}

        _ ->
          {:error, %Auth.Domain{log: "Cannot find person ~#{handle}", error: @auth_fail_msg}}
      end
    end
  end

  def load_user({:ok, %Auth.Domain{} = auth}, handle), do: load_user(auth, handle)

  ##############################################################################
  def load_password_factor(auth = %Auth.Domain{user: user = %User{}}) do
    case Factor.Lib.preloaded_with(user, :password) do
      %User{factors: []} = user ->
        Logger.metadata(uid: user.id)
        {:error, %Auth.Domain{auth | log: "No auth factor for user"}}

      %User{factors: [factor | _]} = user ->
        Logger.metadata(uid: user.id)
        {:ok, %Auth.Domain{auth | factor: factor}}

      _error ->
        Logger.metadata(uid: user.id)
        {:error, %Auth.Domain{auth | log: "Unexpected result from factor preload"}}
    end
  end

  def load_password_factor({:ok, %Auth.Domain{} = auth}), do: load_password_factor(auth)

  def load_password_factor(pass = %Auth.Domain{}), do: pass

  ##############################################################################
  def check_password(%User{} = user, password) do
    case load_password_factor({:ok, %Auth.Domain{user: user}}) do
      {:ok, %Auth.Domain{factor: %Factor{hash: hashed}}} ->
        check_password(hashed, password)

      _ ->
        false
    end
  end

  def check_password(hash, password) when is_binary(hash) and not is_nil(hash),
    do: Factor.Password.verify(password, hash)

  def check_password(_, _), do: false

  @doc """
  """
  @spec valid_user_factor(Auth.Domain.result(), password :: String.t()) :: Auth.Domain.result()
  def valid_user_factor(
        auth = %Auth.Domain{user: %User{}, factor: %Factor{hash: hashed}},
        password
      )
      when not is_nil(hashed) and hashed != "N/A" do
    if check_password(hashed, password) do
      {:ok, %Auth.Domain{auth | status: :authed}}
    else
      {:error, %Auth.Domain{auth | log: "Invalid Password"}}
    end
  end

  def valid_user_factor(auth = %Auth.Domain{}, _),
    do: {:error, %Auth.Domain{auth | log: "No password factor exists for user"}}

  # ##############################################################################
  # @spec post_signin(Auth.Domain.result()) :: Auth.Domain.result()
  # def post_signin({:ok, auth = %Auth.Domain{status: :authed, user: %User{}}}) do
  #   Logger.info("Signin Success", uid: user.id)
  #   # TODO: events/triggers to table/signin count, etc
  #   {:ok, auth}
  # end
  #
  # def post_signin(pass = {:error, %Auth.Domain{}}), do: pass
end
