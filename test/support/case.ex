defmodule Rivet.Data.Adi.Case do
  use ExUnit.CaseTemplate

  using do
    quote location: :keep do
      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Rivet.Data.Adi.Case
      import Rivet.Data.Adi.Test.Factory
      alias Rivet.Data.Repo
      alias Ecto.Changeset
    end
  end

  setup tags do
    opts = tags |> Map.take([:isolation]) |> Enum.to_list()
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Rivet.Data.Repo, opts)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Rivet.Data.Repo, {:shared, self()})
    end

    :ok
  end
end
