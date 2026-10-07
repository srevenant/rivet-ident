defmodule Rivet.Ident.Email do
  use TypedEctoSchema
  use Rivet.Ecto.Model
  import Rivet.DefEnum
  use Rivet.Ident

  defenum(Status, pending: 0, verified: 1, bouncing: 2, complaint: 3, rejected: 4)

  def sendable?(status) when status in [:pending, :verified], do: true
  def sendable?(_), do: false

  typed_schema "user_emails" do
    belongs_to(:user, User, type: :binary_id, foreign_key: :user_id)
    has_many(:issues, Email.Issue)
    field(:address, :string)
    field(:primary, :boolean, default: false)
    field(:verified, :boolean, default: false)
    field(:status, Status, default: :pending)
    timestamps()
  end

  @required_fields [:user_id, :address]
  use Rivet.Ecto.Collection,
    not_found: :atom,
    required: @required_fields,
    update: [:address, :primary, :verified, :status]

  def validate(chgset) do
    chgset
    |> validate_required(@required_fields)
    |> validate_format(:address, ~r/[a-z0-9+_-]@[a-z0-9-]+\.[a-z0-9-]/i,
      message: "needs to be a valid email address"
    )
    |> unique_constraint(:address, message: "is already registered")
    |> update_change(:address, &String.downcase/1)
  end
end
