defmodule Cato.Data.Auth.Action do
  @moduledoc """
  Schema for representing and working with a Auth.Acces.Db.
  """
  use TypedEctoSchema
  use Unify.Ecto.Model, id_type: :int

  typed_schema "saasy_actions" do
    field(:name, ADI.Utils.EctoAtom)
    field(:description, :string)
  end

  use Unify.Ecto.Collection, required: [:name], update: [:description, :name]
end
