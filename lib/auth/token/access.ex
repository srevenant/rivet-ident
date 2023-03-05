defmodule Rivet.Auth.Token.Access do
  alias Rivet.Auth.Token
  alias Rivet.Data.Ident

  @doc ~S"""
  Generate an auth JWT to our specification

  iex> alias Rivet.Data.Ident.Factor
  iex> {:ok, token, claims} = jwt(%Factor{id: "AB", details: %{type: "acc"}}, "example.com", 5*60)
  iex> claims.aud
  "caa1:acc:example.com"
  iex> claims.sub
  "cas1:AB"
  iex> String.slice(token, 0..1)
  "ey"

  iex> {:ok, token, claims} = jwt("narf", "example.com", 5*60)
  iex> claims.aud
  "caa1:acc:example.com"
  iex> claims.sub
  "cas1:narf"
  iex> String.slice(token, 0..1)
  "ey"

  iex> {:ok, "ey" <> _rest, %{sub: "cas1:userid"}} = jwt("userid", "hostname")
  """
  @spec jwt(
          target :: Ident.Factor.t(),
          hostname :: String.t(),
          testing_only_expiration_offset :: nil | integer()
        ) ::
          {:ok, token :: String.t(), claims :: map()}
  def jwt(factor, hostname, exp \\ 0)

  def jwt(%Ident.Factor{details: %{type: "acc"}} = factor, hostname, exp) do
    exp = if is_number(exp) and exp > 0, do: exp, else: Rivet.Auth.Settings.expire_limit(:acc)
    Token.Create.jwt(:acc, "cas1:#{factor.id}", hostname, exp)
  end

  def jwt(user_id, hostname, exp)
      when is_binary(user_id) and is_integer(exp) and is_binary(hostname),
      do: Token.Create.jwt(:acc, "cas1:#{user_id}", hostname, exp)
end
