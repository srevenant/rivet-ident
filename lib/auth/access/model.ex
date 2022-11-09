defmodule Cato.Data.Auth.Access do
  @moduledoc """
  Schema for representing and working with a Auth.Acces.Db.
  """
  use TypedEctoSchema
  use Unify.Ecto.Model, id_type: :int
  import EctoEnum

  # Access domains are per table type so you can map accesses to individual
  # rows in a table (such as different accesses for different groups in the db),
  # where :global is ... global and not tied to another data type.
  defenum(Domains,
    global: 0
    # "Elixir.Cato.Data.Auth.AdiGroups": 1
  )

  typed_schema "saasy_accesses" do
    belongs_to(:user, Auth.User, type: :binary_id, foreign_key: :user_id)
    belongs_to(:role, Auth.Role, foreign_key: :role_id)
    field(:domain, Domains, default: 0)
    field(:ref_id, :binary_id)
  end

  use Unify.Ecto.Collection,
    required: [:user_id, :role_id],
    update: [:domain, :ref_id],
    unique: [:role_id]
end
