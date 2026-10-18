defmodule Rivet.Ident.Test.Auth.AuthTest do
  use Rivet.Ident.Support.Case, async: true
  alias Rivet.Auth

  doctest Rivet.Auth.Refresh, import: true
  doctest Rivet.Auth.Signin.Google.KeyManager, import: true
  doctest Rivet.Auth.Token, import: true
  doctest Rivet.Auth.Token.Check, import: true
  doctest Rivet.Auth.Token.Create, import: true
end
