defmodule Rivet.Ident.Test.Ident.Role.MapTest do
  use Rivet.Ident.Support.Case, async: true
  alias Rivet.Ident.Role

  test "model tests" do
    assert %Role.Map{id} = insert(:ident_role_map)
    assert is_integer(id)
    assert %Role.Map{id: ^id} = Role.Map.one!(id: id)
    params = params_with_assocs(:ident_role_map)
    assert {:ok, %Role.Map{} = x} = Role.Map.create(params)
    assert {:ok, _} = Role.Map.delete(x)
  end
end
