defmodule Rivet.Ident.Role do
  use TypedEctoSchema
  use Rivet.Ecto.Model, id_type: :int

  typed_schema "ident_roles" do
    field(:name, Rivet.Utils.Ecto.Atom)
    field(:description, :string)
    many_to_many(:actions, Rivet.Ident.Action, join_through: Rivet.Ident.RoleMap, unique: true)
  end

  use Rivet.Ecto.Collection,
    required: [:name, :description],
    update: [:description, :name]
end
