defmodule Rivet.Ident.Test.RoleTest do
  use Rivet.Ident.Case, async: true
  alias Rivet.Ident.Role

  test "model tests" do
    assert %Role{id} = insert(:ident_role)
    assert is_integer(id)
    assert %Role{id: ^id} = Role.one!(id: id)
    params = params_with_assocs(:ident_role)
    assert {:ok, %Role{} = x} = Role.create(params)
    assert {:ok, _} = Role.delete(x)
  end
end
