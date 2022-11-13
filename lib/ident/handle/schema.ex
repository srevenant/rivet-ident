defmodule Rivet.Data.Ident.Handle.Schema do
  @moduledoc false
  use Ecto.Migration
  use Rivet.Data.Ident

  def change do
    ############################################################################
    # separate username so it can be left blank and not have unique constraint problems
    create table(@ident_table_handles, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:user_id, references(:users, on_delete: :delete_all, type: :uuid), null: false)
      add(:handle, :citext, null: false)
      timestamps()
    end

    create(unique_index(@ident_table_handles, [:handle]))
  end
end
