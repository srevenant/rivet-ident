defmodule Rivet.Ident.User.Data do
  use TypedEctoSchema
  use Rivet.Ecto.Model
  use Rivet.Ident

  typed_schema "user_datas" do
    belongs_to(:user, User, type: :binary_id, foreign_key: :user_id)
    # configuration defined; see Rivet.Ident
    field(:type, __MODULE__.Types)
    field(:value, :map)
    timestamps()
  end

  use Rivet.Ecto.Collection,
    not_found: :atom,
    required: [:user_id, :type, :value],
    update: [:value],
    unique: [:type]
end
