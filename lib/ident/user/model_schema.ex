defmodule Rivet.Ident.User.ModelSchema do
  defmacro __using__(_opts) do
    quote do
      use Ecto.Schema

      import Rivet.Ident.User.Schema

      @primary_key {:id, :binary_id, autogenerate: true}
    end
  end

  defmacro rivet_fields do
    quote do
      has_one(:handle, Ident.Handle, on_delete: :delete_all)
      has_many(:emails, Ident.Email, on_delete: :delete_all)
      has_many(:phones, Ident.Phone, on_delete: :delete_all)
      has_many(:data, Ident.User.Data, on_delete: :delete_all)
      field(:name, :string)
      # todo: switch to use a sub-schema and/or struct
      field(:settings, :map, default: %{})
      field(:last_seen, :utc_datetime)
      has_many(:factors, Ident.Factor, on_delete: :delete_all)
      has_many(:accesses, Ident.Access, on_delete: :delete_all)
      # has_many(:tags, Ident.TagUser, on_delete: :delete_all)
      has_many(:ext_ids, Ident.User.ExtId, on_delete: :delete_all)
      has_many(:codes, Ident.User.Code, on_delete: :delete_all)

      field(:type, Types, default: :unknown)
      field(:authz, Rivet.Ecto.MapSet, default: nil, virtual: true)
      field(:state, :map, default: %{}, virtual: true)
      timestamps()
    end
  end
end
