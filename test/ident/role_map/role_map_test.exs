defmodule Rivet.Ident.Test.RoleMapTest do
  use Rivet.Ident.Case, async: true

  doctest Rivet.Ident.RoleMap, import: true
  doctest Rivet.Ident.RoleMap.Lib, import: true

  describe "factory" do
    test "factory creates a valid instance" do
      assert %{} = model = insert(:ident_role_map)
      assert model.id != nil
    end
  end

  describe "build/1" do
    test "build when valid" do
      params = params_with_assocs(:ident_role_map)
      changeset = Rivet.Ident.RoleMap.build(params)
      assert changeset.valid?
    end
  end

  describe "get/1" do
    test "loads saved transactions as expected" do
      c = insert(:ident_role_map)
      assert %Rivet.Ident.RoleMap{} = found = Rivet.Ident.RoleMap.one!(id: c.id)
      assert found.id == c.id
    end
  end

  describe "create/1" do
    test "inserts a valid record" do
      attrs = params_with_assocs(:ident_role_map)
      assert {:ok, model} = Rivet.Ident.RoleMap.create(attrs)
      assert model.id != nil
    end
  end

  describe "delete/1" do
    test "deletes record" do
      model = insert(:ident_role_map)
      assert {:ok, deleted} = Rivet.Ident.RoleMap.delete(model)
      assert deleted.id == model.id
    end
  end
end
