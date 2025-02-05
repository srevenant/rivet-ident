defmodule Rivet.Auth.Signin.Local do
  @moduledoc """
  Local login scheme
  """
  alias Rivet.Auth
  alias Rivet.Ident
  import Ident.User.Lib, only: [check_user_status: 1]

  @spec signup(String.t(), params :: map()) :: Auth.Domain.result()
  def signup(host, args, type \\ :authed)

  def signup(
        hostname,
        %{"handle" => handle, "password" => password, "email" => eaddr},
        type
      )
      when is_binary(hostname) do
    case Ident.Email.one([address: eaddr], [:user]) do
      {:ok, %Ident.Email{}} ->
        {:error, %Auth.Domain{error: "A signin already exists for `#{eaddr}`"}}

      _ ->
        Ident.User.Lib.Signup.signup(
          %Auth.Domain{
            hostname: hostname,
            input: %{
              handle: Ident.Handle.Lib.gen_good_handle(handle),
              secret: password,
              email: %{address: eaddr, verified: false}
            }
          },
          type
        )
    end
  end

  def signup(_, _, _) do
    {:error,
     %Auth.Domain{log: "Auth signup failed, arguments don't match", error: "Signup Failed"}}
  end

  ##############################################################################
  @spec check(Auth.Domain.t() | String.t(), params :: map()) :: Auth.Domain.result()
  def check(%Auth.Domain{} = auth, %{"handle" => handle, "password" => password}) do
    {:ok, auth}
    |> load_user(handle)
    |> check_user_status
    |> load_password_factor
    |> valid_user_factor(password)
    |> Rivet.Auth.Signin.post_signin()
  end

  def check(hostname, args = %{"handle" => _, "password" => _}) when is_binary(hostname),
    do: check(%Auth.Domain{hostname: hostname}, args)

  ##############################################################################
  @auth_fail_msg "Unable to sign in. Did you want to sign up instead?"
  @spec load_user(Auth.Domain.result(), handle :: String.t()) :: Auth.Domain.result()
  def load_user({:ok, %Auth.Domain{} = auth}, handle) do
    if String.contains?(handle, "@") do
      case Ident.Email.one([address: handle], [:user]) do
        {:ok, email} ->
          {:ok, %Auth.Domain{auth | user: email.user}}

        _ ->
          {:error,
           %Auth.Domain{
             log: "Cannot find email #{handle}",
             error: @auth_fail_msg
           }}
      end
    else
      case Ident.Handle.one([handle: handle], [:user]) do
        {:ok, handle} ->
          {:ok, %Auth.Domain{auth | handle: handle, user: handle.user}}

        _ ->
          {:error,
           %Auth.Domain{
             log: "Cannot find person ~#{handle}",
             error: @auth_fail_msg
           }}
      end
    end
  end

  ##############################################################################
  @spec load_password_factor(Auth.Domain.result()) :: Auth.Domain.result()
  def load_password_factor({:ok, auth = %Auth.Domain{user: user = %Ident.User{}}}) do
    case Ident.Factor.Lib.preloaded_with(user, :password) do
      %Ident.User{factors: []} = user ->
        Logger.metadata(uid: user.id)
        {:error, %Auth.Domain{auth | log: "No auth factor for user"}}

      %Ident.User{factors: [factor | _]} = user ->
        Logger.metadata(uid: user.id)
        {:ok, %Auth.Domain{auth | factor: factor}}

      _error ->
        Logger.metadata(uid: user.id)
        {:error, %Auth.Domain{auth | log: "Unexpected result from factor preload"}}
    end
  end

  def load_password_factor(pass = {:error, %Auth.Domain{}}), do: pass

  ##############################################################################
  @spec check_password(hash :: String.t() | Ident.User.t(), password :: String.t()) :: boolean()
  def check_password(%Ident.User{} = user, password) do
    case load_password_factor({:ok, %Auth.Domain{user: user}}) do
      {:ok, %Auth.Domain{factor: %Ident.Factor{hash: hashed}}} ->
        check_password(hashed, password)

      _ ->
        false
    end
  end

  def check_password(hash, password) when is_binary(hash) and not is_nil(hash) do
    Bcrypt.verify_pass(password, hash)
  end

  def check_password(_, _), do: false

  @doc """
  """
  @spec valid_user_factor(Auth.Domain.result(), password :: String.t()) :: Auth.Domain.result()
  def valid_user_factor(
        {:ok, auth = %Auth.Domain{user: %Ident.User{}, factor: %Ident.Factor{hash: hashed}}},
        password
      )
      when not is_nil(hashed) and hashed != "N/A" do
    if check_password(hashed, password) do
      {:ok, %Auth.Domain{auth | status: :authed}}
    else
      {:error, %Auth.Domain{auth | log: "Invalid Password"}}
    end
  end

  def valid_user_factor({:ok, auth = %Auth.Domain{}}, _) do
    {:error, %Auth.Domain{auth | log: "No password factor exists for user"}}
  end

  def valid_user_factor(pass = {:error, %Auth.Domain{}}, _), do: pass
  #
  # ##############################################################################
  # @spec post_signin(Auth.Domain.result()) :: Auth.Domain.result()
  # def post_signin({:ok, auth = %Auth.Domain{status: :authed, user: %Ident.User{}}}) do
  #   Logger.info("Signin Success", uid: user.id)
  #   # TODO: events/triggers to table/signin count, etc
  #   {:ok, auth}
  # end
  #
  # def post_signin(pass = {:error, %Auth.Domain{}}), do: pass
end
