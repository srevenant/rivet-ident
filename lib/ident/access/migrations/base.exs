defmodule Rivet.Data.Ident.Access.Migrations.Base do
  @moduledoc false
  use Ecto.Migration
  use Rivet.Data.Ident.Config

  def change do
    create table(@ident_table_accesses, @ident_schema_args) do
      add(:user_id, references(:users, on_delete: :delete_all, type: :uuid))
      add(:role_id, references(:auth_roles, on_delete: :delete_all))
      add(:domain, :integer, default: 0)
      add(:ref_id, :binary_id, default: nil)
    end

    create(index(@ident_table_accesses, [:domain, :ref_id], @ident_schema_args))

    create(unique_index(@ident_table_accesses, [:user_id, :role_id, :domain, :ref_id], @ident_schema_args))
  end
end
