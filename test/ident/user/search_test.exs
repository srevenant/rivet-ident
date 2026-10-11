defmodule Rivet.Ident.Test.Ident.User.SearchTest do
  use Rivet.Ident.Test.Case, async: true
  alias Rivet.Ident.User.Search

  doctest Search.Admin, import: true
  doctest Search.LegacyPublic, import: true

  test "build_query" do
    cols = [
      %{n: "name", v: ["bob"]},
      %{n: "services", v: [Ecto.UUID.generate()]}
    ]

    assert {:ok,
            %{
              joins: [_],
              order_bys: [_, _],
              wheres: [_, _]
            }} = Search.build_search_query(cols)

    assert {:ok, %{status: %{success: true}}} = Search.search(%{filter: cols})
  end
end
