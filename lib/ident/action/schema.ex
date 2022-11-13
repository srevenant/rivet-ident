defmodule Rivet.Data.Ident.Action.Schema do
  @moduledoc false
  use Ecto.Migration
  use Rivet.Data.Ident

  def change do
    create table(@ident_table_actions) do
      add(:name, :citext)
      add(:description, :text)
    end

    create(unique_index(@ident_table_actions, [:name]))
  end
end
