defmodule Rivet.Ident.Access.Migrations.V12ChangeDomain do
  @moduledoc false
  use Ecto.Migration

  def change do
    execute("""
    ALTER TABLE ident_access
    ALTER COLUMN domain TYPE SMALLINT
    USING CASE domain
      WHEN 'global' THEN 0
      WHEN 'Elixir.Core.Db.Org' THEN 1
      WHEN 'Elixir.Core.Db.Project' THEN 2
    END;
    """)
  end
end
