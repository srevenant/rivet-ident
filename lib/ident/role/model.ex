defmodule Rivet.Ident.Role do
  use TypedEctoSchema
  use Rivet.Ecto.Model, id_type: :intid

  typed_schema "ident_roles" do
    field(:name, Rivet.Ecto.Atom)
    field(:domain, Rivet.Ident.Access.Domains, default: :global)
    field(:description, :string)

    many_to_many(:actions, Rivet.Ident.Action,
      join_through: Rivet.Ident.Role.Map,
      unique: true
    )
  end

  use Rivet.Ecto.Collection,
    not_found: :atom,
    required: [:name, :description],
    update: [:description, :name, :domain]
end
