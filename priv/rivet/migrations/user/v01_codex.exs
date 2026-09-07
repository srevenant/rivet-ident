defmodule Rivet.Ident.User.Migrations.V01Codex do
  use Ecto.Migration

  def change do
    alter table(:users) do
      modify(:name, :citext)
      modify(:type, :smallint)
      add_if_not_exists(:house, :smallint, null: true)
      add_if_not_exists(:sites, :map, default: %{}, null: false)
    end

    create_if_not_exists(index(:users, [:house], using: :hash))
  end
end
