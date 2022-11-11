defmodule Rivet.Data.Auth.Role do
  use TypedEctoSchema
  use Unify.Ecto.Model, id_type: :int

  typed_schema "saasy_roles" do
    field(:name, Rivet.Utils.EctoAtom)
    field(:domain, Rivet.Data.Auth.Acces.Db.Domains, default: :global)
    field(:description, :string)
  end

  use Unify.Ecto.Collection,
    required: [:name, :description],
    update: [:description, :name, :domain]
end
