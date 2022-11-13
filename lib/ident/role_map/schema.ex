defmodule Rivet.Data.Ident.RoleMap.Schema do
  @moduledoc false
  use Ecto.Migration
  use Rivet.Data.Ident

  def change do
    create table(@ident_table_role_maps) do
      add(:role_id, references(:auth_roles, on_delete: :delete_all))
      add(:action_id, references(:auth_actions, on_delete: :delete_all))
    end

    create(unique_index(@ident_table_role_maps, [:role_id, :action_id]))
  end
end
