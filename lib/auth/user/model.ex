defmodule Rivet.Data.Auth.User do
  @moduledoc """
  Schema for representing and working with a Auth.User.
  """
  use TypedEctoSchema
  import EctoEnum
  use Unify.Ecto.Model

  defenum(Types,
    unknown: 0,
    identity: 1,
    identity_signedout: 3,
    authed: 2,
    hidden: 4,
    disabled: 200
  )

  typed_schema "users" do
    belongs_to(:tenant, Auth.Tenant, type: :binary_id, foreign_key: :tenant_id)
    has_one(:handle, Auth.UserHandle, on_delete: :delete_all)
    has_many(:emails, Auth.UserEmail, on_delete: :delete_all)
    has_many(:phones, Auth.UserPhone, on_delete: :delete_all)
    has_many(:data, Auth.UserData, on_delete: :delete_all)
    field(:name, :string)
    # todo: switch to use a sub-schema and/or struct
    field(:settings, :map, default: %{})
    field(:last_seen, :utc_datetime)
    has_many(:factors, Auth.Factor, on_delete: :delete_all)
    has_many(:accesses, Auth.Access, on_delete: :delete_all)
    has_many(:tags, Auth.TagUser, on_delete: :delete_all)

    field(:type, Types, default: :unknown)
    field(:authz, Rivet.Utils.EctoMapSet, default: nil, virtual: true)
    field(:state, :map, default: %{}, virtual: true)
    timestamps()
  end

  use Unify.Ecto.Collection, update: [:settings, :name, :last_seen, :type]
end
