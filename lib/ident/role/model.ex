defmodule Rivet.Ident.Role do
  use TypedEctoSchema
  use Rivet.Ecto.Model, id_type: :int

  import EctoEnum

  defenum(Type, global: 0, domain: 1, mixed: 2)

  typed_schema "ident_roles" do
    field(:name, Rivet.Utils.Ecto.Atom)
    field(:description, :string)
    field(:type, Type, default: :global)
    many_to_many(:actions, Rivet.Ident.Action, join_through: Rivet.Ident.RoleMap, unique: true)
  end

  use Rivet.Ecto.Collection,
    required: [:name, :description],
    update: [:description, :name, :type]
end
