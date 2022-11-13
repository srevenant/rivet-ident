defmodule Rivet.Data.Ident.UserCode.Schema do
  @moduledoc false
  use Ecto.Migration
  use Rivet.Data.Ident

  def change do
    ############################################################################
    create table(@ident_table_user_codes) do
      add(:user_id, references(:users, on_delete: :delete_all, type: :uuid))
      add(:type, :integer)
      add(:code, :citext)
      add(:meta, :map)
      add(:expires, :utc_datetime)

      timestamps()
    end

    create(unique_index(@ident_table_user_codes, [:user_id, :type, :code]))
  end
end
