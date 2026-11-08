defmodule Rivet.Ident.User.Code.Migrations.V04Types do
  @moduledoc false
  use Ecto.Migration

  def change do
    execute("""
    ALTER TABLE user_codes
    ALTER COLUMN type DROP DEFAULT,
    ALTER COLUMN type TYPE SMALLINT
    USING CASE type
      WHEN 'password_reset' THEN 0
      WHEN 'email_verify' THEN 1
      WHEN 'download' THEN 2
      WHEN 'delete_request' THEN 3
    END;
    """)

    flush()

    alter table(:user_codes) do
      modify(:type, :smallint, default: 0)
    end
  end
end
