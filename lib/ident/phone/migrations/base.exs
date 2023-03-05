defmodule Rivet.Data.Ident.Phone.Migrations.Base do
  @moduledoc false
  use Ecto.Migration

  def change do
    ############################################################################
    create table(:user_phones, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:user_id, references(:users, on_delete: :delete_all, type: :uuid))
      add(:number, :string)
      add(:primary, :boolean)
      add(:verified, :boolean)
      timestamps()
    end

    create(index(:user_phones, [:user_id, :number], using: :hash))
  end
end
