defmodule Rivet.Ident.Access.Migrations.ChangeDomain do
  @moduledoc false
  use Ecto.Migration

  def change do
    alter table(:ident_accesses) do
      modify(:domain, :string, default: "global")
    end
  end
end
