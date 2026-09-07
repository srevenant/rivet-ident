defmodule Rivet.Ident.User.Data.Migrations.V01Index do
  use Ecto.Migration

  def change do
    create(index(:user_datas, [:user_id]))
  end
end
