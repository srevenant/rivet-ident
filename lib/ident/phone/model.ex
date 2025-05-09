defmodule Rivet.Ident.Phone do
  alias Rivet.Ident
  use TypedEctoSchema
  use Rivet.Ecto.Model

  typed_schema "user_phones" do
    belongs_to(:user, Ident.User, type: :binary_id, foreign_key: :user_id)
    field(:number, :string)
    field(:primary, :boolean, default: false)
    field(:verified, :boolean, default: false)
    timestamps()
  end

  use Rivet.Ecto.Collection,
    not_found: :atom,
    required: [:user_id, :number],
    update: [:number, :primary, :verified]
end
