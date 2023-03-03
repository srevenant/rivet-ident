defmodule Rivet.Data.Ident.Factor.Migrations.Base do
  @moduledoc false
  use Ecto.Migration

  def change do
    ############################################################################
    create table(:ident_factors, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:user_id, references(:users, on_delete: :delete_all, type: :uuid))
      add(:type, :integer, null: false)
      add(:fedtype, :integer, null: false)
      add(:name, :string)
      add(:value, :string)
      add(:expires_at, :integer)
      add(:details, :map)
      add(:hash, :text)
      timestamps()
    end

    create(index(:ident_factors, [:user_id, :type, :name]))
    create(index(:ident_factors, [:user_id, :type, :expires_at]))
  end
end
