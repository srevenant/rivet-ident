defmodule Cato.Data.Auth.UserPhone do
  @moduledoc """
  Schema for representing and working with a Auth.UserPhone.
  """
  use TypedEctoSchema
  use Unify.Ecto.Model

  typed_schema "user_phones" do
    belongs_to(:user, Auth.User, type: :binary_id, foreign_key: :user_id)
    field(:number, :string)
    field(:primary, :boolean, default: false)
    field(:verified, :boolean, default: false)
    timestamps()
  end

  use Unify.Ecto.Collection,
    required: [:user_id, :number],
    update: [:number, :primary, :verified]
end
