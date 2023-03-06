defmodule Rivet.Data.Ident.Role.Graphql do
  @moduledoc false
  use Absinthe.Schema.Notation
  import Rivet.Data.Ident.Role.Resolver

  @desc "Authorization Ident.Role"
  object :role do
    field(:id, non_null(:integer))
    field(:name, non_null(:string))
    field(:description, non_null(:string))
  end

  object :role_queries do
    field :user_roles, list_of(:role) do
      arg(:name, :string)
      resolve(&query_roles/2)
    end
  end
end
