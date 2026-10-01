defmodule Rivet.Ident.Email.Migrations.V02Issues do
  use Ecto.Migration

  def change do
    alter table(:user_emails) do
      remove(:bounce)
      add(:status, :smallint, default: 0, null: false)
    end

    create table(:user_email_issues, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:type, :smallint, null: false)
      add(:email_id, references(:user_emails, on_delete: :delete_all, type: :uuid))
      add(:issue, :map, null: false)
      timestamps()
    end
  end
end
