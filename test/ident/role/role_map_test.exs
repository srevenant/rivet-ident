defmodule Rivet.Ident.Test.RoleMapTest do
  use Rivet.Ident.Case, async: true
  alias Rivet.Ident.RoleMap

  test "model tests" do
    assert %RoleMap{id} = insert(:ident_role_map)
    assert is_integer(id)
    assert %RoleMap{id: ^id} = RoleMap.one!(id: id)
    params = params_with_assocs(:ident_role_map)
    assert {:ok, %RoleMap{} = x} = RoleMap.create(params)
    assert {:ok, _} = RoleMap.delete(x)
  end
end
