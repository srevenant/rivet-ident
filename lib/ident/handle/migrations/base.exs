defmodule Rivet.Data.Ident.Handle.Migrations.Base do
  @moduledoc false
  use Ecto.Migration

  def change do
    ############################################################################
    # separate username so it can be left blank and not have unique constraint problems
    create table(:user_handles, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:user_id, references(:users, on_delete: :delete_all, type: :uuid), null: false)
      add(:handle, :citext, null: false)
      timestamps()
    end

    create(unique_index(:user_handles, [:handle]))
    create(index(:user_handles, [:user_id]))
  end
end
