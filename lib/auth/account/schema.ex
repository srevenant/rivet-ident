defmodule Rivet.Data.Auth.Account.Schema do
  @moduledoc """
  """
  use Ecto.Migration

  def change do
    create table(:accounts, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:short_id, :citext)
      add(:name, :string)
      timestamps()
    end

    create(unique_index(:accounts, [:shortid]))
  end
end
