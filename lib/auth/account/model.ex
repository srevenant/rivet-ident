defmodule Rivet.Data.Auth.Account do
  @moduledoc """
  """

  use TypedEctoSchema
  use Rivet.Ecto.Model

  typed_schema "accounts" do
    field(:short_id, :string)
    field(:name, :string)
    timestamps()
  end

  use Rivet.Ecto.Collection,
    required: [:name],
    update: [:name, :short_id],
    unique: [:short_id]
end
