defmodule Rivet.Ident.User.Code.Migrations.V02Index do
  @moduledoc false
  use Ecto.Migration

  def change do
    create(unique_index(:user_codes, [:code]))
  end
end
