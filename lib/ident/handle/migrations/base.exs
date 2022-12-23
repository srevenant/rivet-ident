defmodule Rivet.Data.Ident.Handle.Migrations.Root do
  @moduledoc false
  use Ecto.Migration

  def change do
    create table(:handle) do
    #  add(:user_id, references(:users, on_delete: :delete_all, type: :uuid))
      timestamps()
    end

    #create(index(:auth_accesses, [:domain, :ref_id]))
  end
end
