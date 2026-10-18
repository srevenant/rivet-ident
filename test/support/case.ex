defmodule Rivet.Ident.Support.Case do
  use ExUnit.CaseTemplate

  using do
    quote location: :keep do
      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Rivet.Ident.Support.Case

      use ExMachina.Ecto, repo: Rivet.Ident.Test.Repo
      use Rivet.Ident.Test.IdentFactory

      alias Rivet.Ident.Test.Repo
      alias Rivet.Ident
      alias Ecto.Changeset

      use Rivet.Ident
    end
  end

  setup tags do
    opts = tags |> Map.take([:isolation]) |> Enum.to_list()
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Rivet.Ident.Test.Repo, opts)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Rivet.Ident.Test.Repo, {:shared, self()})
    end

    :ok
  end
end
