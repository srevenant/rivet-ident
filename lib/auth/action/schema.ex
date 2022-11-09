defmodule Cato.Data.Auth.Action.Schema do
  @moduledoc false
  use Ecto.Migration

  def change do
    # az = authz / authorization
    create table(:auth_actions) do
      add(:name, :citext)
      add(:description, :text)
    end

    create(unique_index(:auth_actions, [:name]))
  end
end
