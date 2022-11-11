defmodule Rivet.Data.Auth.RoleMap do
  @moduledoc """
  Schema for representing and working with a Auth.RoleMap.
  """
  use TypedEctoSchema
  use Rivet.Ecto.Model, id_type: :int

  typed_schema "saasy_role_maps" do
    belongs_to(:action, Auth.Action, foreign_key: :action_id)
    belongs_to(:role, Auth.Role, foreign_key: :role_id)
  end

  use Rivet.Ecto.Collection, required: [:action_id, :role_id], unique: [:action_id]
end
