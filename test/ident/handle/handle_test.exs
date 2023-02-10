defmodule Rivet.Data.Ident.Test.HandleTest do
  use Rivet.Data.Ident.Case, async: true

  doctest Rivet.Data.Ident.Handle, import: true
  doctest Rivet.Data.Ident.Handle.Db, import: true
  doctest Rivet.Data.Ident.Handle.Loader, import: true
  doctest Rivet.Data.Ident.Handle.Seeds, import: true
  doctest Rivet.Data.Ident.Handle.Graphql, import: true
  doctest Rivet.Data.Ident.Handle.Resolver, import: true
  doctest Rivet.Data.Ident.Handle.Rest, import: true
  doctest Rivet.Data.Ident.Handle.Cache, import: true

  describe "factory" do
    test "factory creates a valid instance" do
      assert %{} = model = insert(:handle)
      assert model.id != nil
    end
  end

  describe "build/1" do
    test "build when valid" do
      params = params_with_assocs(:handle)
      changeset = Rivet.Data.Ident.Handle.build(params)
      assert changeset.valid?
    end
  end

  describe "get/1" do
    test "loads saved transactions as expected" do
      c = insert(:handle)
      assert %Rivet.Data.Ident.Handle{} = found = Rivet.Data.Ident.Handle.one!(id: c.id)
      assert found.id == c.id
    end
  end

  describe "create/1" do
    test "inserts a valid record" do
      attrs = params_with_assocs(:handle)
      assert {:ok, model} = Rivet.Data.Ident.Handle.create(attrs)
      assert model.id != nil
    end
  end

  describe "delete/1" do
    test "deletes record" do
      model = insert(:handle)
      assert {:ok, deleted} = Rivet.Data.Ident.Handle.delete(model)
      assert deleted.id == model.id
    end
  end
end
