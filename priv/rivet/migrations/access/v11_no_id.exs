defmodule Rivet.Ident.Access.Migrations.V11NoId do
  use Ecto.Migration

  def change do
    alter table(:ident_accesses) do
      # NOTE: this leaves us with no primary key(even compound) on the table,
      # and that's fine; we have a unique index on the four keys and we cannot
      # make them a primary key as nulls are allowed for ref_id. So just no-id
      # and a unique index is sufficient.
      remove(:id)
    end
  end
end
