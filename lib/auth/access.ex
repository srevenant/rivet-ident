defmodule Rivet.Auth.Access do
  @moduledoc """
  Validation of tokens for accessing site (after refresh)

  Note: this is the start of the next iteration, and it will replace
  Rivet.Auth.Token
  """
  alias Rivet.Auth.Domain
  alias Rivet.Auth.Token
  alias Rivet.Data.Ident

  @doc """
  iex> alias Rivet.Auth.Domain
  iex> check([""], %Domain{})
  {:missing, %Domain{log: "Missing authorization header value"}}
  iex> check([], %Domain{})
  {:missing, %Domain{log: "Missing authorization header value"}}
  iex> check(["bearer token"], %Domain{})
  {:error, %Domain{log: "Invalid authorization"}}
  iex> check(["narf"], %Domain{})
  {:error, %Domain{log: "Authorization header exists but is not formatted properly"}}
  iex> check(["narf narf"], %Domain{})
  {:error, %Domain{log: "Invalid authorization type: narf"}}
  """

  @spec check(auth_header :: list(String.t()), Domain.t()) ::
          {:ok | :missing | :error, Domain.t()}
  # | def(check([], %Domain{} = auth),
  #     do: {:missing, %Domain{auth | log: "Missing authorization header"}}
  #   )
  def check([""], %Domain{} = auth),
    do: {:missing, %Domain{auth | log: "Missing authorization header value"}}

  def check([header], %Domain{} = auth) do
    with [type, tok] <- String.split(header, " ", parts: 2) do
      case String.downcase(type) do
        "bearer" -> {:bearer, tok}
        # add alternate token types here
        "cxs" -> {:cxs, tok}
        _ -> {:error, %Domain{auth | log: "Invalid authorization type: #{type}"}}
      end
    else
      _ ->
        {:error, %Domain{auth | log: "Authorization header exists but is not formatted properly"}}
    end
    |> process_authorization(auth)
  end

  def check(_, %Domain{} = auth),
    do: {:missing, %Domain{auth | log: "Missing authorization header value"}}

  # Standard bearer tokens for users
  defp process_authorization({:bearer, token}, auth) do
    case Token.Verify.jwt(token, :acc) do
      {:error, reason} ->
        {:error, %Domain{auth | log: reason}}

      {:ok, claims} ->
        auth = %Domain{auth | status: :authed, token: %{ref: token, claims: claims}}

        # this checks the validation token embedded within the refresh token
        case Token.Check.jwt(auth) |> Ident.User.Lib.check_user_status() do
          {:ok, %Domain{} = auth} -> {:ok, auth}
          # we passed signature, but the claims weren't right
          {:error, %Domain{} = auth} -> {:error, %Domain{auth | status: :unknown}}
        end
    end
  end

  defp process_authorization({:cxs, _token}, auth) do
    # TODO
    {:error, %Domain{auth | log: "CXS authorization not reimplemented yet"}}
  end

  defp process_authorization(pass, _), do: pass
end
