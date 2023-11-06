defmodule Rivet.Ident.UserCode do
  @moduledoc """
  Schema for representing and working with a Ident.UserCode.
  """
  use TypedEctoSchema
  use Rivet.Ecto.Model, id_type: :int
  alias Rivet.Ident

  typed_schema "user_codes" do
    belongs_to(:user, Ident.User, type: :binary_id, foreign_key: :user_id)
    field(:type, Rivet.Utils.Ecto.Atom)
    field(:code, :string)
    field(:meta, :map, default: %{})
    field(:expires, :utc_datetime)
    timestamps()
  end

  use Rivet.Ecto.Collection,
    required: [:user_id, :code, :type, :expires],
    update: [:meta],
    foreign_keys: [:user_id]
end
