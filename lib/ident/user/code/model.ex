defmodule Rivet.Ident.User.Code do
  @moduledoc """
  Schema for representing and working with a Ident.User.Code.
  """
  use TypedEctoSchema
  use Rivet.Ecto.Model, id_type: :intid
  alias Rivet.Ident

  @doc """

  This feels like excess structure but its to assert a standard format to some
  known types. use of type!/1 isn't required, it just helps us keep our existing
  Rivet.Ident stuff honest.

  """
  def type!(:email_verify), do: :email_verify
  def type!(:delete_request), do: :delete_request
  def type!(:password_reset), do: :password_reset
  def type!(_), do: raise("Invalid User.Code")

  typed_schema "user_codes" do
    belongs_to(:user, Ident.User, type: :binary_id, foreign_key: :user_id)
    field(:type, Rivet.Ecto.Atom)
    field(:code, :string)
    field(:used, :boolean)
    field(:meta, :map, default: %{})
    field(:expires, :utc_datetime)
    timestamps()
  end

  use Rivet.Ecto.Collection,
    not_found: :atom,
    required: [:user_id, :code, :type, :expires],
    update: [:meta, :used],
    foreign_keys: [:user_id]
end
