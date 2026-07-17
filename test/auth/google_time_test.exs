defmodule Rivet.GoogleTimeTest do
  use Rivet.Ident.Case, async: true
  import Rivet.Auth.Signin.Google.KeyManager, only: [parse_rfc1123_datetime: 1]

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
end
