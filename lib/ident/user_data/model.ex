defmodule Rivet.Ident.UserData do
  @moduledoc """
  Schema for representing and working with a Ident.UserData.
  """
  use TypedEctoSchema
  use Rivet.Ecto.Model
  import EctoEnum
  alias Rivet.Ident

  defenum(Types,
    available: 0,
    address: 2,
    profile: 4,
    toggles: 5,
    save: 6
  )

  typed_schema "user_datas" do
    belongs_to(:user, Ident.User, type: :binary_id, foreign_key: :user_id)
    field(:type, Types)
    field(:value, :map)
    timestamps()
  end

  use Rivet.Ecto.Collection,
    not_found: :atom,
    required: [:user_id, :type, :value],
    update: [:value],
    unique: [:type]
end
