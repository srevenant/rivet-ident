defmodule Rivet.Ident.Email.Migrations.Base do
  @moduledoc false
  use Ecto.Migration
  # use Rivet.Ident.Config

  def change do
    ############################################################################
    # TODO: Mapping table for many users to one email
    create table(:user_emails, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:user_id, references(:users, on_delete: :delete_all, type: :uuid))
      add(:address, :citext)
      add(:primary, :boolean)
      add(:verified, :boolean)
      timestamps()
    end

    create(unique_index(:user_emails, [:address]))
    create(index(:user_emails, [:user_id], using: :hash))
  end
end
