defmodule Rivet.Ident.Email.Migrations.Bounce do
  @moduledoc false
  use Ecto.Migration
  # use Rivet.Ident.Config

  def change do
    alter table(:user_emails) do
      add(:bounce, {:array, :map})
    end
  end
end
