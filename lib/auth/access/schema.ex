defmodule Cato.Data.Auth.Acces.Db.Schema do
  @moduledoc false
  use Ecto.Migration

  def change do
    create table(:auth_accesses) do
      add(:user_id, references(:users, on_delete: :delete_all, type: :uuid))
      add(:role_id, references(:auth_roles, on_delete: :delete_all))
      add(:domain, :integer, default: 0)
      add(:ref_id, :binary_id, default: nil)
    end

    create(index(:auth_accesses, [:domain, :ref_id]))

    create(
      unique_index(:auth_accesses, [:user_id, :role_id, :domain, :ref_id],
        name: :accesses_unique_index
      )
    )
  end
end
