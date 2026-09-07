defmodule Rivet.Ident.Factor.Migrations.V01Updates do
  use Ecto.Migration

  def change do
    alter table(:ident_factors) do
      modify(:type, :smallint, null: false)
      modify(:fedtype, :smallint, null: false)
    end

    create(index(:ident_factors, [:user_id, :type]))
  end
end
