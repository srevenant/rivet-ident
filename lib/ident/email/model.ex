defmodule Rivet.Ident.Email do
  @moduledoc """
  Schema for representing and working with a Ident.Email.
  """
  use TypedEctoSchema
  use Rivet.Ecto.Model
  alias Rivet.Ident

  typed_schema "user_emails" do
    belongs_to(:user, Ident.User, type: :binary_id, foreign_key: :user_id)
    field(:address, :string)
    field(:primary, :boolean, default: false)
    field(:verified, :boolean, default: false)
    field(:bounce, {:array, :map})
    timestamps()
  end

  @required_fields [:user_id, :address]
  use Rivet.Ecto.Collection,
    required: @required_fields,
    update: [:address, :primary, :verified]

  def validate(chgset) do
    chgset
    |> validate_required(@required_fields)
    |> validate_format(:address, ~r/[a-z0-9+-]@[a-z0-9-]+\.[a-z0-9-]/i,
      message: "needs to be a valid email address"
    )
    |> unique_constraint(:address, message: "is already registered")
  end
end
