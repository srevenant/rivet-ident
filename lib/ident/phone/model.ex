defmodule Rivet.Data.Ident.Phone do
  alias Rivet.Data.Ident
  use TypedEctoSchema
  use Rivet.Ecto.Model
  use Rivet.Data.Ident.Config

  typed_schema "#{@ident_table_phones}" do
    belongs_to(:user, Ident.User, type: :binary_id, foreign_key: :user_id)
    field(:number, :string)
    field(:primary, :boolean, default: false)
    field(:verified, :boolean, default: false)
    timestamps()
  end

  use Rivet.Ecto.Collection,
    required: [:user_id, :number],
    update: [:number, :primary, :verified]
end
