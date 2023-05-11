defmodule Rivet.Ident.Test.AccessTest do
  use Rivet.Ident.Case, async: true

  doctest Rivet.Ident.Access, import: true
  doctest Rivet.Ident.Access.Lib, import: true
  doctest Rivet.Ident.Access.Loader, import: true
  doctest Rivet.Ident.Access.Seeds, import: true

  doctest Rivet.Ident.Access.Rest, import: true
  doctest Rivet.Ident.Access.Cache, import: true

  describe "factory" do
    test "factory creates a valid instance" do
      assert %{} = model = insert(:ident_access)
      assert model.id != nil
    end
  end

  describe "build/1" do
    test "build when valid" do
      params = params_with_assocs(:ident_access)
      changeset = Rivet.Ident.Access.build(params)
      assert changeset.valid?
    end
  end

  describe "get/1" do
    test "loads saved transactions as expected" do
      c = insert(:ident_access)
      assert %Rivet.Ident.Access{} = found = Rivet.Ident.Access.one!(id: c.id)
      assert found.id == c.id
    end
  end

  describe "create/1" do
    test "inserts a valid record" do
      attrs = params_with_assocs(:ident_access)
      assert {:ok, model} = Rivet.Ident.Access.create(attrs)
      assert model.id != nil
    end
  end

  describe "delete/1" do
    test "deletes record" do
      model = insert(:ident_access)
      assert {:ok, deleted} = Rivet.Ident.Access.delete(model)
      assert deleted.id == model.id
    end
  end
end
