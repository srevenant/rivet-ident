defmodule Rivet.Ident.Role.Migrations.Base do
  @moduledoc false
  use Ecto.Migration

  def change do
    create table(:ident_roles) do
      add(:name, :string)
      add(:subscription, :boolean, default: false)
      add(:description, :text)
    end

    create(unique_index(:ident_roles, [:name]))
  end
end
