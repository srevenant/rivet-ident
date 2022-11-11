defmodule Rivet.Data.Auth.UserData.Schema do
  @moduledoc false
  use Ecto.Migration

  def change do
    ############################################################################
    create table(:user_datas, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:user_id, references(:users, on_delete: :delete_all, type: :uuid), null: true)
      add(:type, :integer, default: 0)
      add(:value, :map, default: %{})
      timestamps()
    end

    create(index(:user_datas, [:user_id]))
    create(unique_index(:user_datas, [:user_id, :type]))
  end
end
