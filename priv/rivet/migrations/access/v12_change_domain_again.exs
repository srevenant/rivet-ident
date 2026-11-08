defmodule Rivet.Ident.Access.Migrations.V12ChangeDomainAgain do
  @moduledoc false
  use Ecto.Migration

  def change do
    # for codex only:
    execute("""
    ALTER TABLE ident_accesses
    ALTER COLUMN domain DROP DEFAULT,
    ALTER COLUMN domain TYPE SMALLINT
    USING CASE domain
      WHEN 'global' THEN 0
      WHEN 'Elixir.Core.Db.Org' THEN 1
      WHEN 'Elixir.Core.Db.Project' THEN 2
    END;
    """)

    flush()

    alter table(:ident_accesses) do
      modify(:domain, :smallint, default: 0)
    end
  end
end
