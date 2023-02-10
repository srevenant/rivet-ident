defmodule Rivet.Data.Ident.Case do
  use ExUnit.CaseTemplate

  using do
    quote location: :keep do
      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Rivet.Data.Ident.Case
      import Rivet.Data.Ident.Test.Factory
      alias Rivet.Data.Ident.Repo
      alias Ecto.Changeset
    end
  end

  setup tags do
    opts = tags |> Map.take([:isolation]) |> Enum.to_list()
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Rivet.Data.Ident.Repo, opts)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Rivet.Data.Ident.Repo, {:shared, self()})
    end

    :ok
  end
end
