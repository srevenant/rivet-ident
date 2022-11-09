defmodule Cato.Data.Auth.Role.Schema do
  @moduledoc false
  use Ecto.Migration

  def change do
    create table(:auth_roles) do
      add(:name, :string)
      add(:subscription, :boolean, default: false)
      add(:description, :text)
      add(:domain, :integer, default: 0)
    end

    create(unique_index(:auth_roles, [:name]))
  end
end
