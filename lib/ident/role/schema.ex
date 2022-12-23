defmodule Rivet.Data.Ident.Role.Schema do
  @moduledoc false
  use Ecto.Migration
  use Rivet.Data.Ident.Config

  def change do
    create table(@ident_table_roles) do
      add(:name, :string)
      add(:subscription, :boolean, default: false)
      add(:description, :text)
      add(:domain, :integer, default: 0)
    end

    create(unique_index(@ident_table_roles, [:name]))
  end
end
