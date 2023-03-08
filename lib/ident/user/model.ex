defmodule Rivet.Ident.User do
  @moduledoc """
  Schema for representing and working with a Ident.User.
  """
  use TypedEctoSchema
  import EctoEnum
  alias Rivet.Ident
  use Rivet.Ecto.Model

  defenum(Types,
    unknown: 0,
    identity: 1,
    identity_signedout: 3,
    authed: 2,
    hidden: 4,
    disabled: 200
  )

  typed_schema "users" do
    has_one(:handle, Ident.Handle, on_delete: :delete_all)
    has_many(:emails, Ident.Email, on_delete: :delete_all)
    has_many(:phones, Ident.Phone, on_delete: :delete_all)
    has_many(:data, Ident.UserData, on_delete: :delete_all)
    field(:name, :string)
    # todo: switch to use a sub-schema and/or struct
    field(:settings, :map, default: %{})
    field(:last_seen, :utc_datetime)
    has_many(:factors, Ident.Factor, on_delete: :delete_all)
    has_many(:accesses, Ident.Access, on_delete: :delete_all)
    # has_many(:tags, Ident.TagUser, on_delete: :delete_all)

    field(:type, Types, default: :unknown)
    field(:authz, Rivet.Utils.Ecto.MapSet, default: nil, virtual: true)
    field(:state, :map, default: %{}, virtual: true)
    timestamps()
  end

  use Rivet.Ecto.Collection, update: [:settings, :name, :last_seen, :type]

  def enabled?(%__MODULE__{type: type}), do: type != :disabled
  def enabled?(_), do: false
end
