defmodule Rivet.Data.Ident.Test.Factory do
  use ExMachina.Ecto, repo: Rivet.Auth.Repo
  use Rivet.Data.Ident.Test.AuthFactory
end
