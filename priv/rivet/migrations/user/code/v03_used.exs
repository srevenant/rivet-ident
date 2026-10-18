defmodule Rivet.Ident.User.Code.Migrations.V03Used do
  @moduledoc false
  use Ecto.Migration

  def change do
    alter table(:user_codes) do
      add(:used, :boolean, null: false, default: false)
    end
  end
end
