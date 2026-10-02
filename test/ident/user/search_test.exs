defmodule Rivet.Ident.Test.User.SearchTest do
  use Rivet.Ident.Case, async: true
  alias Core.Db.Ident.User.Search

  doctest Search.Admin, import: true
  doctest Search.LegacyPublic, import: true

  test "build_query" do
    cols = [
      %{n: "name", v: ["bob"]},
      %{n: "services", v: [Ecto.UUID.generate()]}
      # %{n: "allows", v: ["libmail"]}
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
