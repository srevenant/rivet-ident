defmodule Rivet.Ident.Test.Auth.AuthTest do
  use Rivet.Ident.Support.Case, async: true
  alias Rivet.Auth

  doctest Rivet.Auth.Refresh, import: true
  doctest Rivet.Auth.Token.Create, import: true
end
