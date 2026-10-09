defmodule Rivet.Ident.Test.Support.Factory do
  use ExMachina.Ecto, repo: Rivet.Auth.Repo
  use Rivet.Ident.Test.Support.IdentFactory
end
