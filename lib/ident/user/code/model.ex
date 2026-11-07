defmodule Rivet.Ident.User.Code do
  use TypedEctoSchema
  use Rivet.Ecto.Model, id_type: :intid
  use Rivet.Ident
  # import Rivet.Ecto.DefAppEnum

  # def_app_enum(Types, :rivet_ident, :user_code_types)
  import Rivet.Ecto.DefEnum
  defenum(Types, @user_code_types)

  typed_schema "user_codes" do
    belongs_to(:user, Ident.User, type: :binary_id, foreign_key: :user_id)
    field(:type, Types)
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
