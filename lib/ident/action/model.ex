defmodule Rivet.Ident.Action do
  use TypedEctoSchema
  use Rivet.Ecto.Model, id_type: :intid

  typed_schema "ident_actions" do
    field(:name, Rivet.Ecto.Atom)
    field(:description, :string)
  end

  use Rivet.Ecto.Collection, not_found: :atom, required: [:name], update: [:description, :name]
end
