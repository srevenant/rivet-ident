defmodule Cato.Data.Auth.UserCode.Schema do
  @moduledoc false
  use Ecto.Migration

  def change do
    ############################################################################
    create table(:user_codes) do
      add(:user_id, references(:users, on_delete: :delete_all, type: :uuid))
      add(:type, :integer)
      add(:code, :citext)
      add(:meta, :map)
      add(:expires, :utc_datetime)

      timestamps()
    end

    create(unique_index(:user_codes, [:user_id, :type, :code]))
  end
end
