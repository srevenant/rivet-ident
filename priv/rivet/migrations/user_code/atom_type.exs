defmodule Rivet.Ident.UserCode.Migrations.AtomType do
  @moduledoc false
  use Ecto.Migration

  def change do
    drop index(:user_codes, [:user_id, :type, :code])

    alter table(:user_codes) do
      add(:atom_type, :string)
    end

    flush()

    repo().query("""
      UPDATE user_codes SET atom_type = CASE type
        WHEN 0 THEN "password_reset"
        WHEN 1 THEN "email_verify"
        WHEN 2 THEN "file_download"
        ELSE NULL END
    """)

    flush()

    alter table(:user_codes) do
      remove(:type)
    end

    rename(table(:user_codes), :atom_type, to: :type)

    create(unique_index(:user_codes, [:user_id, :type, :code]))
  end
end
