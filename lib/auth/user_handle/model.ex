defmodule Rivet.Data.Auth.UserHandle do
  @moduledoc """
  Schema for representing and working with a Handle.
  """
  use TypedEctoSchema
  use Unify.Ecto.Model
  import Rivet.Utils.EctoChangeset, only: [validate_rex: 4]

  typed_schema "user_handles" do
    belongs_to(:user, Auth.User, type: :binary_id, foreign_key: :user_id)
    belongs_to(:tenant, Auth.Tenant, type: :binary_id, foreign_key: :tenant_id)
    field(:handle, :string)
    timestamps()
  end

  @required_fields [:user_id, :tenant_id, :handle]
  use Unify.Ecto.Collection,
    required: @required_fields,
    update: [:handle]

  @impl Unify.Ecto.Collection
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
    |> unique_constraint(:handle, name: :users_tenant_handle_index)
  end
end
