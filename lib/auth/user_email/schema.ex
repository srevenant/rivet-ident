defmodule Rivet.Data.Auth.UserEmail.Schema do
  @moduledoc false
  use Ecto.Migration

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
  end
end
