defmodule Rivet.Data.Auth.UserEmail do
  @moduledoc """
  Schema for representing and working with a Auth.UserEmail.
  """
  use TypedEctoSchema
  use Rivet.Ecto.Model

  typed_schema "user_emails" do
    belongs_to(:user, Auth.User, type: :binary_id, foreign_key: :user_id)
    field(:address, :string)
    field(:primary, :boolean, default: false)
    field(:verified, :boolean, default: false)
    timestamps()
  end

  @required_fields [:user_id, :tenant_id, :address]
  use Rivet.Ecto.Collection,
    required: @required_fields,
    update: [:address, :primary, :verified]

  def validate(chgset) do
    chgset
    |> validate_required(@required_fields)
    |> validate_format(:address, ~r/[a-z0-9+-]@[a-z0-9-]+\.[a-z0-9-]/i,
      message: "needs to be a valid email address"
    )
    |> unique_constraint(:address,
      name: :user_emails_tenant_id_address_index,
      message: "is already registered"
    )
  end
end
