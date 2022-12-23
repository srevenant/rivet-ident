defmodule Rivet.Data.Ident.User.Migrations.Base do
  @moduledoc false
  use Ecto.Migration

  def change do
    execute("CREATE EXTENSION IF NOT EXISTS citext", "DROP EXTENSION IF EXISTS citext")

    ############################################################################
    # keep users at the base -- it's well enough known not to be confused
    create table(:users, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      # add(:tenant_id, references(:saasy_tenants, on_delete: :delete_all, type: :uuid))
      add(:name, :string)
      add(:settings, :map)
      add(:last_seen, :utc_datetime)
      add(:type, :integer)
      timestamps()
    end
  end
end
