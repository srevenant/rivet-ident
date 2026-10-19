defmodule Rivet.Ident.Test.Ident.Access.ModelTest do
  use Rivet.Ident.Support.Case, async: true
  alias Rivet.Ident.Access
  alias Access.Lib

  test "model tests" do
    assert %Access{id} = insert(:ident_access)
    assert is_integer(id)
    assert %Access{id: ^id} = Access.one!(id: id)
    params = params_with_assocs(:ident_access)
    assert {:ok, %Access{} = x} = Access.create(params)
    assert {:ok, _} = Access.delete(x)
  end

  describe "Lib" do
    setup do
      user = insert(:ident_user)
      role = insert(:ident_role)
      action = insert(:ident_action)
      ref1 = Ecto.UUID.generate()
      ref2 = Ecto.UUID.generate()
      {:ok, %{user, role, action, ref1, ref2}}
    end

    test "add and get_actions", %{user, role, action, ref1, ref2} do
      insert(:ident_role_map, role: role, action: action)

      # good add
      assert {:ok, _} = Lib.add(user, role.name, :project, ref1)
      assert {:ok, _} = Lib.add(user, role.name, :project, ref2)
      # bad add
      assert {:error, _} = Lib.add(user, :nope, :project, ref2)

      # get_actions
      assert MapSet.new([{action.name, :project, ref1}]) == Lib.get_actions(user, :project, ref1)
      assert MapSet.new([{action.name, :project, ref2}]) == Lib.get_actions(user, :project, ref2)
      assert MapSet.new() == Lib.get_actions(user, :project, Ecto.UUID.generate())
      assert MapSet.size(Lib.get_actions(user)) == 2
    end

    test "drop", %{user, role, ref1} do
      assert {:ok, access} = Lib.add(user, role.name, :project, ref1)
      assert {:ok, %Access{}} = Lib.drop(user, role.name, :project, ref1)
      assert {:error, :not_found} = Access.one(id: access.id)
      assert {:error, "cannot find access link"} = Lib.drop(user, role.name, :project, ref1)

      assert {:error, "cannot find role definitely_missing_role"} =
               Lib.drop(user, :definitely_missing_role)
    end

    test "delete_user_domain removes only matching access", %{user, role, ref1, ref2} do
      other = insert(:ident_user)

      {:ok, a1} = Lib.add(user, role.name, :project, ref1)
      {:ok, a2} = Lib.add(user, role.name, :project, ref2)
      {:ok, a3} = Lib.add(user, role.name, :global)
      {:ok, a4} = Lib.add(other, role.name, :project, ref1)

      Lib.delete_user_domain(user.id, :project, ref1)

      assert {:error, :not_found} = Access.one(id: a1.id)
      assert {:ok, _} = Access.one(id: a2.id)
      assert {:ok, _} = Access.one(id: a3.id)
      assert {:ok, _} = Access.one(id: a4.id)
    end

    test "delete_user_access removes all access for one user", %{user, role} do
      other = insert(:ident_user)

      {:ok, a1} = Lib.add(user, role.name, :global)
      {:ok, a2} = Lib.add(user, role.name, :project, Ecto.UUID.generate())
      {:ok, a3} = Lib.add(other, role.name, :global)

      Lib.delete_user_access(user.id)

      assert {:error, :not_found} = Access.one(id: a1.id)
      assert {:error, :not_found} = Access.one(id: a2.id)
      assert {:ok, _} = Access.one(id: a3.id)
    end
  end
end
