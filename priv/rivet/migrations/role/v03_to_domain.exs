defmodule Elixir.Rivet.Ident.Role.Migrations.V03ToDomain do
  @moduledoc false
  use Ecto.Migration

  def change do
    # for cato:
    rename(table(:ident_roles), :type, to: :domain)

    flush()

    alter table(:ident_roles) do
      modify(:domain, :smallint, null: false)
    end
  end
end
