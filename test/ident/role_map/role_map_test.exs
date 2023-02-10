defmodule Rivet.Data.Ident.Test.RoleMapTest do
  use Rivet.Data.Ident.Case, async: true

  doctest Rivet.Data.Ident.RoleMap, import: true
  doctest Rivet.Data.Ident.RoleMap.Db, import: true
  doctest Rivet.Data.Ident.RoleMap.Loader, import: true
  doctest Rivet.Data.Ident.RoleMap.Seeds, import: true
  doctest Rivet.Data.Ident.RoleMap.Graphql, import: true
  doctest Rivet.Data.Ident.RoleMap.Resolver, import: true
  doctest Rivet.Data.Ident.RoleMap.Rest, import: true
  doctest Rivet.Data.Ident.RoleMap.Cache, import: true

  describe "factory" do
    test "factory creates a valid instance" do
      assert %{} = model = insert(:role_map)
      assert model.id != nil
    end
  end

  describe "build/1" do
    test "build when valid" do
      params = params_with_assocs(:role_map)
      changeset = Rivet.Data.Ident.RoleMap.build(params)
      assert changeset.valid?
    end
  end

  describe "get/1" do
    test "loads saved transactions as expected" do
      c = insert(:role_map)
      assert %Rivet.Data.Ident.RoleMap{} = found = Rivet.Data.Ident.RoleMap.one!(id: c.id)
      assert found.id == c.id
    end
  end

  describe "create/1" do
    test "inserts a valid record" do
      attrs = params_with_assocs(:role_map)
      assert {:ok, model} = Rivet.Data.Ident.RoleMap.create(attrs)
      assert model.id != nil
    end
  end

  describe "delete/1" do
    test "deletes record" do
      model = insert(:role_map)
      assert {:ok, deleted} = Rivet.Data.Ident.RoleMap.delete(model)
      assert deleted.id == model.id
    end
  end
end
