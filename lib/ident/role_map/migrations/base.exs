defmodule Rivet.Data.Ident.RoleMap.Migrations.Base do
  @moduledoc false
  use Ecto.Migration

  def change do
    create table(:auth_role_maps) do
      add(:role_id, references(:auth_roles, on_delete: :delete_all))
      add(:action_id, references(:auth_actions, on_delete: :delete_all))
    end

    create(
      unique_index(:auth_role_maps, [:role_id, :action_id],
        name: :role_maps_role_id_action_id_index
      )
    )
  end
end
