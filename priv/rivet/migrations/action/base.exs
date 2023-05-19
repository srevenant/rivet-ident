defmodule Rivet.Ident.Action.Migrations.Base do
  @moduledoc false
  use Ecto.Migration

  def change do
    # az = authz / authorization
    create table(:ident_actions) do
      add(:name, :citext)
      add(:description, :text)
    end

    create(unique_index(:ident_actions, [:name]))
  end
end
