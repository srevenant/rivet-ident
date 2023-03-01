defmodule Rivet.Auth.Signin.Local do
  @moduledoc """
  Local login scheme
  """
  alias Rivet.Auth.Domain
  alias Rivet.Data.Ident
  import Ident.User.Lib, only: [check_user_status: 1]

  @spec signup(String.t(), params :: map()) :: Domain.result()
  def signup(
        hostname,
        %{"handle" => handle, "password" => password, "email" => eaddr}
      )
      when is_binary(hostname) do
    case Ident.Email.one([address: eaddr], [:user]) do
      {:ok, %Ident.Email{}} ->
        {:error, %Domain{error: "A signin already exists for `#{eaddr}`"}}

      _ ->
        Ident.User.Lib.signup(%Domain{
          hostname: hostname,
          input: %{
            handle: Ident.Handle.Lib.gen_good_handle(handle),
            secret: password,
            email: %{address: eaddr, verified: false}
          }
        })
    end
  end

  def signup(_, _) do
    {:error, %Domain{log: "Auth signup failed, arguments don't match", error: "Signup Failed"}}
  end

  ##############################################################################
  @spec check(Domain.t() | String.t(), params :: map()) :: Domain.result()
  def check(%Domain{} = auth, %{"handle" => handle, "password" => password}) do
    {:ok, auth}
    |> load_user(handle)
    |> check_user_status
    |> load_password_factor
    |> valid_user_factor(password)
    |> Rivet.Auth.Signin.post_signin()
  end

  def check(hostname, args = %{"handle" => _, "password" => _}) when is_binary(hostname),
    do: check(%Domain{hostname: hostname}, args)

  ##############################################################################
  @auth_fail_msg "Unable to sign in. Did you want to sign up instead?"
  @spec load_user(Domain.result(), handle :: String.t()) :: Domain.result()
  def load_user({:ok, %Domain{} = auth}, handle) do
    if String.contains?(handle, "@") do
      case Ident.Email.one([address: handle], [:user]) do
        {:ok, email} ->
          {:ok, %Domain{auth | user: email.user}}

        _ ->
          {:error,
           %Domain{
             log: "Cannot find email #{handle}",
             error: @auth_fail_msg
           }}
      end
    else
      case Ident.Handle.one([handle: handle], [:user]) do
        {:ok, handle} ->
          {:ok, %Domain{auth | handle: handle, user: handle.user}}

        _ ->
          {:error,
           %Domain{
             log: "Cannot find person ~#{handle}",
             error: @auth_fail_msg
           }}
      end
    end
  end

  ##############################################################################
  @spec load_password_factor(Domain.result()) :: Domain.result()
  def load_password_factor({:ok, auth = %Domain{user: user = %Ident.User{}}}) do
    user = Ident.Factor.Lib.preloaded_with(user, :password)

    case user.factors do
      [] ->
        Logger.metadata(uid: user.id)
        {:error, %Domain{auth | log: "No auth factor for user"}}

      [factor | _] ->
        Logger.metadata(uid: user.id)
        {:ok, %Domain{auth | factor: factor}}
    end
  end

  def load_password_factor(pass = {:error, %Domain{}}), do: pass

  ##############################################################################
  @spec check_password(hash :: String.t() | Ident.User.t(), password :: String.t()) :: boolean()
  def check_password(%Ident.User{} = user, password) do
    case load_password_factor({:ok, %Domain{user: user}}) do
      {:ok, %Domain{factor: %Ident.Factor{hash: hashed}}} ->
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
  @spec valid_user_factor(Domain.result(), password :: String.t()) :: Domain.result()
  def valid_user_factor(
        {:ok, auth = %Domain{user: %Ident.User{}, factor: %Ident.Factor{hash: hashed}}},
        password
      )
      when not is_nil(hashed) and hashed != "N/A" do
    if check_password(hashed, password) do
      {:ok, %Domain{auth | status: :authed}}
    else
      {:error, %Domain{auth | log: "Invalid Password"}}
    end
  end

  def valid_user_factor({:ok, auth = %Domain{}}, _) do
    {:error, %Domain{auth | log: "No password factor exists for user"}}
  end

  def valid_user_factor(pass = {:error, %Domain{}}, _), do: pass
  #
  # ##############################################################################
  # @spec post_signin(Domain.result()) :: Domain.result()
  # def post_signin({:ok, auth = %Domain{status: :authed, user: %Ident.User{}}}) do
  #   Logger.info("Signin Success", uid: user.id)
  #   # TODO: events/triggers to table/signin count, etc
  #   {:ok, auth}
  # end
  #
  # def post_signin(pass = {:error, %Domain{}}), do: pass
end
