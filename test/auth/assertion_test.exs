defmodule Rivet.Ident.Test.Auth.AssertionTest do
  use Rivet.Ident.Support.Case, async: true
  use Rivet.Ident
  alias Rivet.Auth.Assertion
  import Assertion

  test "action" do
    assert %Assertion{action: :read, domain: :global, fallback: false} = action(:read)

    assert %Assertion{action: :write, domain: :project, ref_id: "123", fallback: true} =
             action(:write, domain: :project, ref_id: "123", fallback: true)
  end

  describe "Check" do
    setup do
      project_id = Ecto.UUID.generate()
      user = insert(:ident_user)
      {:ok, %{user, project_id}}
    end

    test "scoped", %{user, project_id} do
      role = insert(:ident_role, domain: :project)
      %{role, action} = insert(:ident_role_map, role: role)
      assert {:ok, _} = Ident.Access.Lib.add(user, role.name, project_id)

      assert {:ok, _} = check(user, action(action.name, domain: :project, ref_id: project_id))
      assert {:error, _} = web_check(user, action(action.name, domain: :global))

      # side-tap; while we're at it force a reload in Cache
      assert {:ok, %User{}} = Rivet.Auth.Cache.get_authz(user, force: true)


      admin = insert(:ident_user)
      insert(:ident_role_map, 

      assert {:ok, _} =
               check(
                 user,
                 action(action.name, domain: :project, ref_id: project_id, fallback: true)
               )
    end

    test "global", %{user, project_id} do
      # default role is global
      %{role, action} = insert(:ident_role_map)
      assert {:ok, _} = Ident.Access.Lib.add(user, role.name, nil)
      assert {:ok, _} = web_check(user, action(action.name, domain: :global))
      assert {:error, _} = check(user, action(action.name, domain: :project, ref_id: project_id))

    end
  end
end
