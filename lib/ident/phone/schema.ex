defmodule Rivet.Data.Ident.Phone.Schema do
  @moduledoc false
  use Ecto.Migration
  use Rivet.Data.Ident.Config

  def change do
    ############################################################################
    create table(@ident_table_phones, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:user_id, references(:users, on_delete: :delete_all, type: :uuid))
      add(:number, :string)
      add(:primary, :boolean)
      add(:verified, :boolean)
      timestamps()
    end

    # TODO: possibly make this a compile-time option
    # create(index(@ident_table_phones, [:number]))
  end
end
