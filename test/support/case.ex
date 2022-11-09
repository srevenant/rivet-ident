defmodule Cato.Data.Adi.Case do
  use ExUnit.CaseTemplate

  using do
    quote location: :keep do
      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Cato.Data.Adi.Case
      import Cato.Data.Adi.Test.Factory
      alias Cato.Data.Repo
      alias Ecto.Changeset
    end
  end

  setup tags do
    opts = tags |> Map.take([:isolation]) |> Enum.to_list()
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Cato.Data.Repo, opts)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Cato.Data.Repo, {:shared, self()})
    end

    :ok
  end
end
