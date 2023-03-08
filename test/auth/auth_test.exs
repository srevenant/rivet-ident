defmodule Rivet.IdentTest do
  use Rivet.Ident.Case, async: true
  alias Rivet.Auth
  alias Auth.Domain
  alias Auth.Token
  import Rivet.Ident.Test.Factory

  doctest Auth.Access, import: true
  doctest Auth.Refresh, import: true
  doctest Auth.Signin.Google.KeyManager, import: true
  doctest Token, import: true
  doctest Token.Access, import: true
  doctest Token.Check, import: true
  doctest Token.Create, import: true
  # doctest Token.Validation, import: true
  doctest Token.Verify, import: true

  describe "validation" do
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
end

### FWIW the results
# Name            ips        average  deviation         median         99th %
# split      770.69 K        1.30 μs  ±2678.59%           1 μs           2 μs
# regex      269.94 K        3.70 μs   ±767.10%           3 μs           6 μs
#
# Comparison:
# split      770.69 K
# regex      269.94 K - 2.86x slower +2.41 μs
###
# describe "benchmark" do
#   test "benchmark" do
#     list = Enum.to_list(1..10_000)
#     map_fun = fn i -> [i, i * i] end
#     input = "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJjYWExOmN4czpib28iLCJleHAiOjE2MDgzMzE5MTYsImZvciI6e30sInN1YiI6ImNhczE6c3VwZXJ2aXNvciJ9.aNjaH9dlkVVFYZ0gjqDMrYyNDSIEt3CNqThNuNI5WCw"
#
#     Benchee.run(%{
#       "split" => fn ->
#         [type, tok] = String.split(input, " ", parts: 2)
#         case String.downcase(type) do
#           "bearer" -> :ok
#           "cxs" -> :ok
#           _ -> :bad
#         end
#       end,
#       "regex" => fn ->
#         case Regex.split(~r/^(bearer|cxs) */i, input, parts: 2) do
#           nil -> :bad
#           [type, tok] ->
#             case String.downcase(type) do
#               "bearer" -> :ok
#               "cxs" -> :ok
#               _ -> :bad
#             end
#         end
#       end,
#     }, time: 10, warmup: 5)
#   end
# end
