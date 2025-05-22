defmodule Rivet.Auth.Access do
  @moduledoc """
  Validation of tokens for accessing site (after refresh)

  Note: this is the start of the next iteration, and it will replace
  Rivet.Auth.Token
  """
  alias Rivet.Auth
  alias Rivet.Ident

  @doc """
  ```
  iex> alias Rivet.Auth
  iex> check([""], %Auth.Domain{})
  {:missing, %Auth.Domain{log: "Missing authorization header value"}}
  iex> check([], %Auth.Domain{})
  {:missing, %Auth.Domain{log: "Missing authorization header value"}}
  iex> check(["bearer token"], %Auth.Domain{})
  {:error, %Auth.Domain{log: "Invalid authorization"}}
  iex> check(["narf"], %Auth.Domain{})
  {:error, %Auth.Domain{log: "Authorization header exists but is not formatted properly"}}
  iex> check(["narf narf"], %Auth.Domain{})
  {:error, %Auth.Domain{log: "Invalid authorization type: narf"}}
  ```
  """

  @spec check(auth_header :: list(String.t()), Auth.Domain.t()) ::
          {:ok | :missing | :error, Auth.Domain.t()}
  # | def(check([], %Auth.Domain{} = auth),
  #     do: {:missing, %Auth.Domain{auth | log: "Missing authorization header"}}
  #   )
  def check([""], %Auth.Domain{} = auth),
    do: {:missing, %Auth.Domain{auth | log: "Missing authorization header value"}}

  def check([header], %Auth.Domain{} = auth) do
    with [type, tok] <- String.split(header, " ", parts: 2) do
      case String.downcase(type) do
        "bearer" -> {:bearer, tok}
        _ -> {:error, %Auth.Domain{auth | log: "Invalid authorization type: #{type}"}}
      end
    else
      _ ->
        {:error,
         %Auth.Domain{auth | log: "Authorization header exists but is not formatted properly"}}
    end
    |> process_authorization(auth)
  end

  def check(_, %Auth.Domain{} = auth),
    do: {:missing, %Auth.Domain{auth | log: "Missing authorization header value"}}

  # Standard bearer tokens for users
  defp process_authorization({:bearer, token}, auth) do
    case Auth.Token.Verify.jwt(token, :acc) do
      {:error, reason} ->
        {:error, %Auth.Domain{auth | log: reason}}

      {:ok, claims} ->
        auth = %Auth.Domain{auth | status: :authed, token: %{ref: token, claims: claims}}

        # this checks the validation token embedded within the refresh token
        case Auth.Token.Check.jwt(auth) |> Ident.User.Lib.check_user_status() do
          {:ok, %Auth.Domain{} = auth} -> {:ok, auth}
          # we passed signature, but the claims weren't right
          {:error, %Auth.Domain{} = auth} -> {:error, %Auth.Domain{auth | status: :unknown}}
        end
    end
  end

  defp process_authorization(pass, _), do: pass
end
