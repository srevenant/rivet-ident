defmodule Cato.Data.Auth.UserCode do
  @moduledoc """
  Schema for representing and working with a Auth.UserCode.
  """
  use TypedEctoSchema
  use Unify.Ecto.Model
  import EctoEnum

  defenum(Types, password_reset: 0, email_verify: 1, file_download: 2)

  typed_schema "user_codes" do
    belongs_to(:user, Auth.User, type: :binary_id, foreign_key: :user_id)
    field(:type, Types)
    field(:code, :string)
    field(:meta, :map, default: %{})
    field(:expires, :utc_datetime)
    timestamps()
  end

  use Unify.Ecto.Collection,
    required: [:user_id, :code, :type, :expires],
    update: [:meta],
    foreign_keys: [:user_id]
end
