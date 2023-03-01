defmodule Rivet.Auth.Token.Verify do
  @moduledoc """
  Verify tokens meet our requirements
  """

  @doc """
  Checks JWT against configured secrets for that type. Returns claims if a
  valid JWT is found, but does no authentication/authorization.

  NOTE: These test will stop working with diff jwt keys

  iex> jwt( "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJjYWExOmFjYzpleGFtcGxlLmNvbSIsImV4cCI6MTY3MTkyMjMwMCwiZm9yIjp7fSwic3ViIjoiY2FzMTpuYXJmIn0.N6PV_XAGTjymi1CEfVkKRj433S0XBlTxcevL7VAhTRY", :acc)
  {:ok, %{aud: "caa1:acc:example.com", exp: 1671922300, for: %{}, sub: "cas1:narf"}}
  """
  def jwt(jwt, type) when is_binary(jwt) and is_atom(type),
    do: jwt(jwt, Rivet.Auth.Settings.secret_keys(type))

  def jwt(jwt, [secret | rest]) do
    case Joken.verify(jwt, Joken.Signer.create("HS256", secret)) do
      {:ok, claims} ->
        {:ok, Transmogrify.transmogrify(claims)}

      {:error, _error} ->
        jwt(jwt, rest)
    end
  end

  def jwt(_jwt, []), do: {:error, "Invalid authorization"}
end
