defmodule Rivet.Data.Ident.Action.Migrations.Base do
  @moduledoc false
  use Ecto.Migration
  use Rivet.Data.Ident.Config

  def change do
    create table(@ident_table_actions, @ident_schema_args) do
      add(:name, :citext)
      add(:description, :text)
    end

    create(unique_index(@ident_table_actions, [:name], @ident_schema_args))
  end
end
