defmodule Rivet.Data.Ident.Factor.Graphql do
  @moduledoc false
  use Absinthe.Schema.Notation
  import Rivet.Graphql
  alias Rivet.Data.Ident.Factor

  scalar :factor_type do
    serialize(&Atom.to_string/1)
    parse(&parse_enum(&1, Factor.Types))
  end

  @desc "An authentication factor"
  object :factor do
    field(:id, non_null(:string))
    field(:user_id, non_null(:string))
    field(:type, :factor_type)
    field(:name, :string)
    field(:expires_at, :integer)
    field(:details, :json)
  end
end
