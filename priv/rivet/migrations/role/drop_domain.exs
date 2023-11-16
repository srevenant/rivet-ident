defmodule Elixir.Rivet.Ident.Role.Migrations.DropDomain do
  @moduledoc false
  use Ecto.Migration

  def change do
    alter table(:ident_roles) do
      remove(:domain)
    end
  end
end
