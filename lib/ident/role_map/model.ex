defmodule Rivet.Ident.RoleMap do
  @moduledoc """
  Schema for representing and working with a Ident.RoleMap.
  """
  use TypedEctoSchema
  use Rivet.Ecto.Model, id_type: :intid
  alias Rivet.Ident

  typed_schema "ident_role_maps" do
    belongs_to(:action, Ident.Action, foreign_key: :action_id)
    belongs_to(:role, Ident.Role, foreign_key: :role_id)
  end

  use Rivet.Ecto.Collection,
    not_found: :atom,
    required: [:action_id, :role_id],
    unique: [[:role_id, :action_id]]
end
