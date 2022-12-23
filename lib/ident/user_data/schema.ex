defmodule Rivet.Data.Ident.UserData.Schema do
  @moduledoc false
  use Ecto.Migration
  use Rivet.Data.Ident.Config

  def change do
    ############################################################################
    create table(@ident_table_user_datas, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:user_id, references(:users, on_delete: :delete_all, type: :uuid), null: true)
      add(:type, :integer, default: 0)
      add(:value, :map, default: %{})
      timestamps()
    end

    create(index(@ident_table_user_datas, [:user_id]))
    create(unique_index(@ident_table_user_datas, [:user_id, :type]))
  end
end
