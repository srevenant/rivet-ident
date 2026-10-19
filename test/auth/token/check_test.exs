defmodule Rivet.Ident.Test.Auth.Token.CheckTest do
  use Rivet.Ident.Support.Case, async: true
  alias Rivet.Auth
  import Auth.Token.Check

  test "validate_subject" do
    assert {:error, %{log: "Unable to process token subject"}} = valid_subject(%Auth.Domain{})

    assert {:error, %{log: "Cannot parse token.sub=red"}} =
             valid_subject(%Auth.Domain{token: %{claims: %{sub: "red"}}, type: :acc})

    assert {:error, %{log: "Cannot find identity factor=subject"}} =
             valid_subject(%Auth.Domain{type: :acc, token: %{sub_type: :cas1, sub: "subject"}})

    assert {:error, %{log: "Cannot find identity factor=subject"}} =
             valid_subject(%Auth.Domain{
               token: %{aud_type: :caa1, sub_type: :cas1, sub: "subject"},
               type: :val
             })

    assert {:error, "narf"} = valid_subject({:error, "narf"})

    %{id} = insert(:ident_factor, type: :unknown)

    assert {:error, %{log: "Provided factor is not a validation token"}} =
             valid_subject(%Auth.Domain{type: :acc, token: %{sub_type: :cas1, sub: id}})

    assert {:error, %{log: "Factor for token is not a validation factor(2)"}} =
             valid_subject(%Auth.Domain{
               type: :val,
               token: %{aud_type: :caa1, sub_type: :cas1, sub: id}
             })

    %{id} = insert(:ident_factor, type: :valtok, value: nil)

    assert {:error, %{log: "Factor for token is not a validation factor"}} =
             valid_subject(%Auth.Domain{
               type: :val,
               token: %{aud_type: :caa1, sub_type: :cas1, sub: id}
             })
  end

  test "validation_check" do
    now = System.os_time(:second)

    assert {:error, %{log: "Token Expired"}} =
             valid_expiration(%Auth.Domain{token: %{claims: %{for: %{}, exp: 0}}, type: :acc})

    assert {:error, %{log: "Token expiration out of bounds"}} =
             valid_expiration(%Auth.Domain{
               token: %{claims: %{for: %{}, exp: now + 300_000}},
               type: :acc
             })

    assert {:error, "narf"} = valid_expiration({:error, "narf"})
  end

  test "validate_audience" do
    assert {:error, %{log: "Cannot parse token.tok=asdf"}} =
             valid_audience(%Auth.Domain{token: %{aud: "asdf"}})

    assert {:error, %{log: "Token audience does not match: 'a.domain' != 'b.domain'"}} =
             valid_audience(%Auth.Domain{token: %{aud: "key:a.domain"}, hostname: "b.domain"})

    assert {:error, "narf"} = valid_audience({:error, "narf"})
  end

  test "enrich_sub_aud" do
    assert {:error, %{log: "Cannot parse token.sub=asdf"}} =
             enrich_sub_aud(%Auth.Domain{token: %{claims: %{sub: "asdf", aud: "asdf"}}})

    assert {:error, _} = enrich_sub_aud(%Auth.Domain{})
  end

  test "jwt" do
    assert {:ok, _token, claims} = Rivet.Auth.Token.Access.jwt("narf", "example.com", 5)

    assert {:error, %Auth.Domain{log: "Cannot find identity factor=narf"}} =
             jwt(%Auth.Domain{hostname: "example.com", token: %{claims: claims}})
  end
end
