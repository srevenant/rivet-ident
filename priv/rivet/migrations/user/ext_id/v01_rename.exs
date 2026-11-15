defmodule Rivet.Ident.User.ExtId.Migrations.V01Rename do
  @moduledoc false
  use Ecto.Migration
  import Rivet.Migration.Helpers

  def change do
    drop(index(:user_idents, [:origin, :ident]))

    flush()

    rename_table(:user_idents, :user_ext_ids, fkeys: [:user_id])

    rename(table(:user_ext_ids), :ident, to: :ext_id)
    create(unique_index(:user_ext_ids, [:origin, :ext_id]))
  end
end
