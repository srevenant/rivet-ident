defmodule Rivet.Ident.Test.Ident.Role.MapTest do
  use Rivet.Ident.Support.Case, async: true
  use Rivet.Ident
  alias Rivet.Ident.Role
  alias Rivet.Ident.Role.Map.Lib

  test "model tests" do
    assert %Role.Map{id} = insert(:ident_role_map)
    assert is_integer(id)
    assert %Role.Map{id: ^id} = Role.Map.one!(id: id)
    params = params_with_assocs(:ident_role_map)
    assert {:ok, %Role.Map{} = x} = Role.Map.create(params)
    assert {:ok, _} = Role.Map.delete(x)
  end

  test "get_actions loads and caches role actions" do
    role = insert(:ident_role)
    action = insert(:ident_action)
    ref_id = Ecto.UUID.generate()

    assert {:ok, _} =
             Ident.Role.Map.create(%{
               role_id: role.id,
               action_id: action.id
             })

    expected = [[action.name, :project, ref_id]]

    # Cache miss: retrieves mappings from database
    assert ^expected = Lib.get_actions(role.id, :project, ref_id)

    # Cache hit: retrieves previously cached actions
    assert ^expected = Lib.get_actions(role.id, :project, ref_id)

    # Overload accepting an Access struct
    access = %Ident.Access{role: role, domain: :project, ref_id: ref_id}
    assert ^expected = Lib.get_actions(access)

    # Direct mapping function
    assert ^expected = Lib.map_actions([role.id, :project, ref_id])
  end

  test "get_actions handles roles without actions" do
    role = insert(:ident_role)
    ref_id = Ecto.UUID.generate()

    assert [] = Lib.get_actions(role.id, :project, ref_id)
    assert [] = Lib.get_actions(role.id, :project, ref_id)
  end
end
