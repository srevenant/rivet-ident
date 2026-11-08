defmodule Rivet.Ident.Access do
  @moduledoc "see Rivet.Ident.Role for explanations on Access/Roles/Maps and users"
  use TypedEctoSchema
  use Rivet.Ecto.Model, id_type: :none
  use Rivet.Ident

  typed_schema "ident_accesses" do
    belongs_to(:user, Ident.User, type: :binary_id, foreign_key: :user_id)
    belongs_to(:role, Ident.Role, foreign_key: :role_id)
    # configuration defined; see Rivet.Ident
    field(:domain, __MODULE__.Domains, default: :global)
    field(:ref_id, :binary_id)
  end

  use Rivet.Ecto.Collection,
    not_found: :atom,
    required: [:user_id, :role_id],
    update: [:domain, :ref_id],
    unique: [:role_id, [:user_id, :role_id, :domain, :ref_id]]

  defdelegate add(a, b, c), to: __MODULE__.Lib
  defdelegate drop(a, b, c), to: __MODULE__.Lib
end
