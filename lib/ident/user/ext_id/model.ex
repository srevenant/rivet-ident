defmodule Rivet.Ident.User.ExtId do
  use TypedEctoSchema
  use Rivet.Ecto.Model, id_type: :none
  alias Rivet.Ident

  typed_schema "user_extid" do
    field(:extid, :string)
    field(:origin, :string)
    belongs_to(:user, Ident.User, type: :binary_id, foreign_key: :user_id)
    timestamps()
  end

  use Rivet.Ecto.Collection, not_found: :atom, create: [], required: [:origin, :extid, :user_id]
end
