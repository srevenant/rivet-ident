defmodule Rivet.Ident.Handle do
  @moduledoc """
  Schema for representing and working with a Handle.
  """
  use TypedEctoSchema
  use Rivet.Ecto.Model
  alias Rivet.Ident
  import Rivet.Utils.Ecto.Changeset, only: [validate_rex: 4]

  typed_schema "user_handles" do
    belongs_to(:user, Ident.User, type: :binary_id, foreign_key: :user_id)
    field(:handle, :string)
    timestamps()
  end

  @required_fields [:user_id, :handle]
  use Rivet.Ecto.Collection,
    not_found: :atom,
    required: @required_fields,
    unique: [:handle],
    update: [:handle]

  @behaviour Rivet.Ecto.Collection
  @impl Rivet.Ecto.Collection
  def validate(chgset) do
    handle = String.downcase(get_change(chgset, :handle))

    chgset
    |> validate_required(@required_fields)
    |> put_change(:handle, handle)
    |> validate_length(:handle, min: 4, max: 32)
    |> validate_rex(:handle, ~r/[^a-z0-9+-]+/,
      not: true,
      message: "may only have characters: a-z0-9+-"
    )
    |> validate_rex(:handle, ~r/(^-|-$)/,
      not: true,
      message: "may not start or end with a dash"
    )
    |> unique_constraint(:handle)
  end
end
