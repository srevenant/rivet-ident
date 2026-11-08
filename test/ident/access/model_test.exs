defmodule Rivet.Ident.Test.Ident.Access.ModelTest do
  use Rivet.Ident.Support.Case, async: true
  alias Rivet.Ident.Access
  alias Access.Lib
  # for the macro
  require Access.Lib

  test "model tests" do
    %{role_id, user_id, domain: :global} = params = params_with_assocs(:ident_access)
    assert {:ok, %Access{}} = Access.create(params)
    assert {1, nil} = Access.delete_all(user_id: user_id, role_id: role_id, domain: :global)
  end

  test "coverage" do
    uuid = Ecto.UUID.generate()

    assert Lib.is_role_key(1)
    assert Lib.is_role_key(:atom)
    refute Lib.is_role_key(uuid)

    assert {:ok, ^uuid} = Lib.valid_user_id(uuid)
    assert {:error, "Invalid user or user id"} = Lib.valid_user_id(1)
  end

  describe "Lib" do
    setup do
      user = insert(:ident_user)
      role = insert(:ident_role, domain: :project)

      ref1 = Ecto.UUID.generate()
      ref2 = Ecto.UUID.generate()
      {:ok, %{user, role, ref1, ref2}}
    end

    test "add and get_actions", %{user, role, ref1, ref2} do
      action = %{name: action_name} = insert(:ident_action)

      insert(:ident_role_map, role: role, action: action)

      assert [] = Lib.action_strings!(user, role.domain, ref1)

      # good add
      assert {:ok, %Access{}} = Lib.add(user, role.name, ref1)
      assert {:ok, %Access{}} = Lib.add(user, role.name, ref2)

      action_name = to_string(action_name)
      assert [^action_name] = Lib.action_strings!(user, role.domain, ref1)

      # bad add
      assert {:error, _} = Lib.add(user, :nope, ref2)

      # get_actions
      assert MapSet.new([{action.name, :project, ref1}]) == Lib.get_actions(user, :project, ref1)
      assert MapSet.new([{action.name, :project, ref2}]) == Lib.get_actions(user, :project, ref2)
      assert MapSet.new() == Lib.get_actions(user, :project, Ecto.UUID.generate())
      assert MapSet.size(Lib.get_actions(user)) == 2
    end

    test "change and drop", %{user, role, ref1, ref2} do
      role2 = insert(:ident_role)

      # project1
      assert {:ok, %Access{}} = Lib.add(user, role.name, ref1)
      # project2
      assert {:ok, %Access{}} = Lib.add(user, role.name, ref2)
      # a global one
      assert {:ok, %Access{}} = Lib.change(:upsert, role2.id, user, nil)

      # before delete we have 3 (we'd use count!, but it aggregates by :id)
      assert [_, _, _] = Access.all!(user_id: user.id)

      assert {:ok, 1} = Lib.drop(user, role.name, ref1)

      # will delete nothing, but exercises change
      assert {:ok, 0} = Lib.change(:remove, role.name, user, ref1)

      # and after delete we still have our other 2
      assert [_, _] = Access.all!(user_id: user.id)

      # drop global
      assert {:ok, 1} = Lib.drop(user, role2.id)

      assert [_] = Access.all!(user_id: user.id)

      assert {:error, :not_found} =
               Access.one(user_id: user.id, role_id: role.id, domain: role.domain, ref_id: ref1)

      assert {:error, "cannot find role=no_such_role"} = Lib.drop(user, :no_such_role)

      assert {:ok, 1} = Lib.delete_access(user.id, role.id, role.domain, ref2)
      assert [] = Access.all!(user_id: user.id)
    end
  end
end
