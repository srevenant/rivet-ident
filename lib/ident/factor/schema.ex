defmodule Rivet.Data.Ident.Factor.Schema do
  @moduledoc false
  use Ecto.Migration
  use Rivet.Data.Ident.Config

  def change do
    ############################################################################
    create table(@ident_table_factors, primary_key: false) do
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

    create(index(@ident_table_factors, [:user_id], using: :hash))
    create(index(@ident_table_factors, [:user_id, :type]))
    create(index(@ident_table_factors, [:user_id, :type, :name]))
    create(index(@ident_table_factors, [:user_id, :type, :expires_at]))
  end
end
