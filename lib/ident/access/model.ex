defmodule Rivet.Ident.Access do
  @moduledoc """
  Schema for representing and working with a Ident.Access.
  """
  use TypedEctoSchema
  use Rivet.Ecto.Model, id_type: :intid
  use Rivet.Ident
  import Rivet.Ecto.DefEnum

  defenum(Domains, @access_domains)

  typed_schema "ident_accesses" do
    belongs_to(:user, Ident.User, type: :binary_id, foreign_key: :user_id)
    belongs_to(:role, Ident.Role, foreign_key: :role_id)
    field(:domain, Domains, default: :global)
    field(:ref_id, :binary_id)
  end

  use Rivet.Ecto.Collection,
    not_found: :atom,
    required: [:user_id, :role_id],
    update: [:domain, :ref_id],
    unique: [:role_id, [:user_id, :role_id, :domain, :ref_id]]
end
