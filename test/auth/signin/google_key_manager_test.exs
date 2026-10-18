defmodule Rivet.Ident.Test.Auth.Signin.GoogleKeyManagerTest do
  use Rivet.Ident.Support.Case
  import Rivet.Auth.Signin.Google.KeyManager

  test "parse_rfc1123_datetime" do
    # example from https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Expires
    assert {:ok, ~U[2015-10-21 07:28:00Z]} =
             parse_rfc1123_datetime("Wed, 21 Oct 2015 07:28:00 GMT")

    # examples from https://timex.hexdocs.pm/parsing.html#supported-standards-and-common-formats
    assert {:ok, ~U[2013-03-05 23:25:19Z]} =
             parse_rfc1123_datetime("Tue, 05 Mar 2013 23:25:19 GMT")

    assert {:ok, ~U[2013-03-06 01:25:19Z]} =
             parse_rfc1123_datetime("Tue, 06 Mar 2013 01:25:19 GMT")
  end

  test "get_certs" do
    assert is_map(Rivet.Auth.Signin.Google.KeyManager.get_certs())
  end
end
