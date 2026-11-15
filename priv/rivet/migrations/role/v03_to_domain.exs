defmodule Elixir.Rivet.Ident.Role.Migrations.V03ToDomain do
  @moduledoc false
  use Ecto.Migration

  def change do
    rename(table(:ident_roles), :type, to: :domain)

    flush()
    execute("update ident_roles set domain = 0 where domain is null")

    alter table(:ident_roles) do
      modify(:domain, :smallint, null: false, default: 0)
    end
  end
end
