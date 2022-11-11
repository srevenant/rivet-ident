defmodule Rivet.Data.Auth.Factor do
  @moduledoc """
  Schema for representing and working with an AuthFactor.
  """
  use TypedEctoSchema
  alias Rivet.Data.Auth
  use Rivet.Ecto.Model, export_json: [:name, :expires_at, :value, :details], id_type: :int
  import EctoEnum

  defenum(Types,
    unknown: 0,
    password: 1,
    federated: 2,
    valtok: 3,
    apikey: 4,
    proxy: 5,
    access: 6
  )

  defenum(FederatedTypes,
    none: 0,
    google: 1,
    linkedin: 2,
    facebook: 3,
    twitter: 4,
    twitch: 5
  )

  typed_schema "saasy_factors" do
    # identity vs authentication
    field(:type, Types)
    field(:fedtype, FederatedTypes, default: :none)
    field(:name, :string)
    field(:expires_at, :integer)
    field(:value, :string)
    field(:details, :map)
    # we put these back as passwords
    field(:password, :string, virtual: true)
    # we don't store these again
    field(:secret, :string, virtual: true)
    field(:hash, :string)
    timestamps()
    belongs_to(:user, Auth.User, type: :binary_id, foreign_key: :user_id)
  end

  @required_fields [:type, :expires_at, :user_id]
  use Rivet.Ecto.Collection, required: @required_fields

  @behaviour Rivet.Ecto.Collection
  @impl Rivet.Ecto.Collection
  def build(params \\ %{}) do
    %__MODULE__{}
    |> cast(params, @required_fields)
    |> validate()
    |> hash_password()
  end

  def hash_password(changeset = %Ecto.Changeset{valid?: true, changes: %{password: pass}}) do
    put_change(changeset, :hash, Utils.Hash.password(pass))
    # consider: delete password: token?
  end

  def hash_password(changeset), do: changeset
end
