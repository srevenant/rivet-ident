defmodule Rivet.Data.Ident.UserIdent do
  use TypedEctoSchema
  use Rivet.Ecto.Model, id_type: :none
  alias Rivet.Data.Ident

  @primary_key false
  typed_schema "user_idents" do
    field(:ident, :string)
    field(:origin, :string)
    belongs_to(:user, Ident.User, type: :binary_id, foreign_key: :user_id)
    timestamps()
  end

  use Rivet.Ecto.Collection,
    create: [],
    required: [:origin, :ident, :user_id]
end
