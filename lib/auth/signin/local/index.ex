defmodule Rivet.Auth.Signin.Local do
  @moduledoc """
  Local login scheme
  """
  alias Rivet.Auth
  use Rivet.Ident

  @spec signup(String.t(), params :: map()) :: Auth.Domain.result()
  def signup(host, args, type \\ :authed)

  def signup(
        hostname,
        %{"handle" => handle, "password" => secret, "email" => address},
        type
      )
      when not_empty_str(hostname) do
    cond do
      invalid_value(handle) ->
        signup_data_error("handle")

      invalid_value(secret) ->
        signup_data_error("password")

      invalid_value(address) ->
        signup_data_error("email")

      true ->
        case Email.one([address: address], [:user]) do
          {:ok, %Email{}} ->
            # is this too much information to disclose?
            signup_error("A signin already exists for `#{address}`")

          _ ->
            handle = Handle.Lib.gen_good_handle!(handle)
            email = %{address, verified: false}
            input = %{secret, handle, email}

            User.Signup.signup(%Auth.Domain{hostname, input}, type)
            |> Auth.Signin.post_signin()
        end
    end
  end

  def signup(_, _, _),
    do: signup_error("Arguments don't match")

  # Rivet.Guard's empty_str is a little different from what we want
  defp invalid_value(x), do: not is_binary(x) or byte_size(x) == 0

  defp signup_data_error(missing) do
    err = "Signup failed; Missing #{missing}"
    signin_error(err, err)
  end

  defp signup_error(log),
    do: signin_error("Signup failed: #{log}", "Signup failed. Perhaps try password recovery?")

  ##############################################################################
  @spec check(Auth.Domain.t() | String.t(), params :: map()) :: Auth.Domain.result()
  def check(%Auth.Domain{user: %User{}} = auth, %{"handle" => handle, "password" => password}) do
    with {:ok, auth} <- load_user(auth, handle),
         {:ok, user} <- User.Lib.check_user_status(auth.user),
         {:ok, auth} <- Auth.Password.valid_password_factor(%{auth | user}, password),
         do: Auth.Signin.post_signin(auth)
  end

  def check(hostname, args = %{"handle" => _, "password" => _}) when is_binary(hostname),
    do: check(%Auth.Domain{hostname: hostname}, args)

  ##############################################################################
  @spec load_user(Auth.Domain.t(), handle :: String.t()) :: Auth.Domain.result()
  def load_user(%Auth.Domain{} = auth, handle) do
    if String.contains?(handle, "@") do
      case Email.one([address: handle], [:user]) do
        {:ok, email} ->
          {:ok, %Auth.Domain{auth | user: email.user}}

        {:error, :not_found} ->
          signin_error("Cannot find email #{handle}")
      end
    else
      case Handle.one([handle: handle], [:user]) do
        {:ok, handle} ->
          {:ok, %Auth.Domain{auth | handle: handle, user: handle.user}}

        {:error, :not_found} ->
          signin_error("Cannot find person ~#{handle}")
      end
    end
  end

  def load_user({:ok, %Auth.Domain{} = auth}, handle), do: load_user(auth, handle)

  @auth_fail_msg "Unable to sign in. Did you want to sign up instead?"
  def signin_error(log, error \\ @auth_fail_msg),
    do: {:error, %Auth.Domain{log, error}}
end
