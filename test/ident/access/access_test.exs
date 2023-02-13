defmodule Rivet.Data.Ident.Test.AccessTest do
  use Rivet.Data.Ident.Case, async: true

  doctest Rivet.Data.Ident.Access, import: true
  doctest Rivet.Data.Ident.Access.Db, import: true
  doctest Rivet.Data.Ident.Access.Loader, import: true
  doctest Rivet.Data.Ident.Access.Seeds, import: true
  doctest Rivet.Data.Ident.Access.Graphql, import: true
  doctest Rivet.Data.Ident.Access.Resolver, import: true
  doctest Rivet.Data.Ident.Access.Rest, import: true
  doctest Rivet.Data.Ident.Access.Cache, import: true

  describe "factory" do
    test "factory creates a valid instance" do
      assert %{} = model = insert(:ident_access)
      assert model.id != nil
    end
  end

  describe "build/1" do
    test "build when valid" do
      params = params_with_assocs(:ident_access)
      changeset = Rivet.Data.Ident.Access.build(params)
      assert changeset.valid?
    end
  end

  describe "get/1" do
    test "loads saved transactions as expected" do
      c = insert(:ident_access)
      assert %Rivet.Data.Ident.Access{} = found = Rivet.Data.Ident.Access.one!(id: c.id)
      assert found.id == c.id
    end
  end

  describe "create/1" do
    test "inserts a valid record" do
      attrs = params_with_assocs(:ident_access)
      assert {:ok, model} = Rivet.Data.Ident.Access.create(attrs)
      assert model.id != nil
    end
  end

  describe "delete/1" do
    test "deletes record" do
      model = insert(:ident_access)
      assert {:ok, deleted} = Rivet.Data.Ident.Access.delete(model)
      assert deleted.id == model.id
    end
  end
end
