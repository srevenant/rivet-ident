defmodule Rivet.Ident.Test.Auth.Token.IndexTest do
  use Rivet.Ident.Support.Case, async: true
  alias Rivet.Auth
  import Auth.Token

  test "extract" do
    jwt =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJjYWExOmFjYzpleGFtcGxl" <>
        "LmNvbSIsImV4cCI6MTY3MTkyMjMwMCwiZm9yIjp7fSwic3ViIjoiY2FzMTpuYXJmIn0" <>
        ".N6PV_XAGTjymi1CEfVkKRj433S0XBlTxcevL7VAhTRY"

    assert {:ok, %{"alg" => "HS256", "typ" => "JWT"},
            %{aud: "caa1:acc:example.com", exp: 1_671_922_300, for: %{}, sub: "cas1:narf"}} =
             extract(jwt, :all)

    assert {:ok, %{aud: "caa1:acc:example.com", exp: 1_671_922_300, for: %{}, sub: "cas1:narf"}} =
             extract(jwt)

    assert {:ok, %{"alg" => "HS256", "typ" => "JWT"}} = extract(jwt, :header)
    assert {:error, "Unable to decode JWT part: asdf"} = extract("asdf.asdf.asdf", :all)

    assert {:error, "Invalid JWT, cannot extract claims"} = extract("asdf", :all)
    assert {:error, "Invalid JWT, cannot extract claims"} = extract("asdf", :claims)
    assert {:error, "Invalid JWT, cannot extract claims"} = extract("asdf", :header)
  end
end
