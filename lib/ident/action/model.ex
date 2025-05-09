defmodule Rivet.Ident.Action do
  @moduledoc """
  Schema for representing and working with a Ident.Action.
  """
  use TypedEctoSchema
  use Rivet.Ecto.Model, id_type: :int

  typed_schema "ident_actions" do
    field(:name, Rivet.Utils.Ecto.Atom)
    field(:description, :string)
  end

  use Rivet.Ecto.Collection, not_found: :atom, required: [:name], update: [:description, :name]
end
