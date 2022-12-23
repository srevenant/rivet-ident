defmodule Rivet.Data.Ident.RoleMap do
  @moduledoc """
  Schema for representing and working with a Ident.RoleMap.
  """
  use TypedEctoSchema
  use Rivet.Data.Ident.Config
  use Rivet.Ecto.Model, id_type: :int

  typed_schema "#{@ident_table_role_maps}" do
    belongs_to(:action, Ident.Action, foreign_key: :action_id)
    belongs_to(:role, Ident.Role, foreign_key: :role_id)
  end

  use Rivet.Ecto.Collection, required: [:action_id, :role_id], unique: [:action_id]
end
