defmodule Rivet.Ident.User.Code do
  use TypedEctoSchema
  use Rivet.Ecto.Model, id_type: :intid
  use Rivet.Ident

  typed_schema "user_codes" do
    belongs_to(:user, Ident.User, type: :binary_id, foreign_key: :user_id)
    # configuration defined; see Rivet.Ident
    field(:type, __MODULE__.Types)
    field(:code, :string)
    field(:used, :boolean)
    field(:meta, :map, default: %{})
    field(:expires, :utc_datetime)
    timestamps()
  end

  use Rivet.Ecto.Collection,
    not_found: :atom,
    required: [:user_id, :code, :type, :expires],
    update: [:meta, :used],
    foreign_keys: [:user_id]
end
