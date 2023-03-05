defmodule Rivet.Data.Ident.Case do
  use ExUnit.CaseTemplate

  using do
    quote location: :keep do
      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Rivet.Data.Ident.Case
      import Rivet.Data.Ident.Test.Factory
      alias Rivet.Auth.Repo
      alias Rivet.Data.Ident
      alias Ecto.Changeset
    end
  end

  setup tags do
    opts = tags |> Map.take([:isolation]) |> Enum.to_list()
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Rivet.Auth.Repo, opts)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Rivet.Auth.Repo, {:shared, self()})
    end

    :ok
  end
end
