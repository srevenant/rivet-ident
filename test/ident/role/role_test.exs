defmodule Rivet.Ident.Test.RoleTest do
  use Rivet.Ident.Case, async: true

  doctest Rivet.Ident.Role, import: true
  doctest Rivet.Ident.Role.Lib, import: true
  doctest Rivet.Ident.Role.Loader, import: true
  doctest Rivet.Ident.Role.Seeds, import: true

  doctest Rivet.Ident.Role.Rest, import: true
  doctest Rivet.Ident.Role.Cache, import: true

  describe "factory" do
    test "factory creates a valid instance" do
      assert %{} = model = insert(:ident_role)
      assert model.id != nil
    end
  end

  describe "build/1" do
    test "build when valid" do
      params = params_with_assocs(:ident_role)
      changeset = Rivet.Ident.Role.build(params)
      assert changeset.valid?
    end
  end

  describe "get/1" do
    test "loads saved transactions as expected" do
      c = insert(:ident_role)
      assert %Rivet.Ident.Role{} = found = Rivet.Ident.Role.one!(id: c.id)
      assert found.id == c.id
    end
  end

  describe "create/1" do
    test "inserts a valid record" do
      attrs = params_with_assocs(:ident_role)
      assert {:ok, model} = Rivet.Ident.Role.create(attrs)
      assert model.id != nil
    end
  end

  describe "delete/1" do
    test "deletes record" do
      model = insert(:ident_role)
      assert {:ok, deleted} = Rivet.Ident.Role.delete(model)
      assert deleted.id == model.id
    end
  end
end
