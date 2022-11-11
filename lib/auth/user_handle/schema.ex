defmodule Rivet.Data.Auth.UserHandle.Schema do
  @moduledoc false
  use Ecto.Migration

  def change do
    ############################################################################
    # separate username so it can be left blank and not have unique constraint problems
    create table(:user_handles, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      # transitive dependency, but used for uniqueness w/tenant
      # add(:tenant_id, :uuid, null: false)
      add(:user_id, references(:users, on_delete: :delete_all, type: :uuid), null: false)
      add(:handle, :citext, null: false)
      timestamps()
    end

    # create(unique_index(:user_handles, [:tenant_id, :handle], name: :users_tenant_handle_index))
    create(unique_index(:user_handles, [:handle]))
  end
end
