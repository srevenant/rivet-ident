defmodule Elixir.Rivet.Ident.Role.Migrations.AddType do
  @moduledoc false
  use Ecto.Migration

  def change do
    alter table(:ident_roles) do
      remove_if_exists(:subscription, :integer)
      add(:type, :integer)
    end
  end
end
