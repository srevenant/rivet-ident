defmodule Rivet.Ident.Access.Migrations.V11NoId do
  use Ecto.Migration

  def change do
    alter table(:ident_accesses) do
      remove(:id)
    end
  end
end
