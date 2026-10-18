defmodule Rivet.Ident.Test.Auth.TokenValidationTest do
  use Rivet.Ident.Support.Case, async: true
  alias Rivet.Auth
  alias Auth.{Domain, Token}

  test "generate validation token" do
    domain = Faker.Internet.domain_name()
    user = insert(:ident_user)

    case Token.Validation.jwt(user, domain) do
      {:ok, jwt, _, factor} ->
        {:ok, claims} = Token.extract(jwt, :claims)
        assert claims.sub == "cas1:#{factor.id}"
        assert claims.aud == "caa1:val:#{domain}"
        assert claims.for.type == "acc"
    end
  end

  test "generate validation key" do
    user = insert(:ident_user)
    domain = Faker.Internet.domain_name()

    case Token.Validation.key(domain, user) do
      {:ok, %{aud: aud, sub: "cas2:" <> sub}} ->
        assert aud == "caa1:ref:#{domain}"
        {:ok, claims} = Token.extract(sub, :claims)
        assert claims.aud == "caa1:val:#{domain}"
        assert claims.for.type == "acc"
    end
  end

  test "refresh request" do
    user = insert(:ident_user)
    domain = Faker.Internet.domain_name()

    with {:ok, %{aud: aud, sec: sec, sub: sub}} <-
           Token.Validation.key(domain, user) do
      auth = %Domain{hostname: domain, user: user}

      {:ok, bad_tok, _} =
        Token.Create.jwt(:ref, sub, domain, nil, "bad secret", %{}, %{aud: aud})

      assert {:error, _} = Auth.Refresh.assure(auth, %{"client_assertion" => bad_tok})
      {:ok, ref_tok, _} = Token.Create.jwt(:ref, sub, domain, nil, sec, %{}, %{aud: aud})
      assert {:ok, _, _} = Auth.Refresh.assure(auth, %{"client_assertion" => ref_tok})
    else
      error ->
        IO.inspect(error, label: "error")
        assert false
    end
  end
end
