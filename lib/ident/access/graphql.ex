defmodule Rivet.Ident.Access.Graphql do
  @moduledoc false
  use Absinthe.Schema.Notation

  object :access do
    field(:actions, list_of(:string))
    field(:roles, list_of(:string))
  end
end
