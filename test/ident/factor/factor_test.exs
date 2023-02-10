defmodule Rivet.Data.Ident.Test.FactorTest do
  use Rivet.Data.Ident.Case, async: true

  doctest Rivet.Data.Ident.Factor, import: true
  doctest Rivet.Data.Ident.Factor.Db, import: true
  doctest Rivet.Data.Ident.Factor.Loader, import: true
  doctest Rivet.Data.Ident.Factor.Seeds, import: true
  doctest Rivet.Data.Ident.Factor.Graphql, import: true
  doctest Rivet.Data.Ident.Factor.Resolver, import: true
  doctest Rivet.Data.Ident.Factor.Rest, import: true
  doctest Rivet.Data.Ident.Factor.Cache, import: true

  describe "factory" do
    test "factory creates a valid instance" do
      assert %{} = model = insert(:factor)
      assert model.id != nil
    end
  end

  describe "build/1" do
    test "build when valid" do
      params = params_with_assocs(:factor)
      changeset = Rivet.Data.Ident.Factor.build(params)
      assert changeset.valid?
    end
  end

  describe "get/1" do
    test "loads saved transactions as expected" do
      c = insert(:factor)
      assert %Rivet.Data.Ident.Factor{} = found = Rivet.Data.Ident.Factor.one!(id: c.id)
      assert found.id == c.id
    end
  end

  describe "create/1" do
    test "inserts a valid record" do
      attrs = params_with_assocs(:factor)
      assert {:ok, model} = Rivet.Data.Ident.Factor.create(attrs)
      assert model.id != nil
    end
  end

  describe "delete/1" do
    test "deletes record" do
      model = insert(:factor)
      assert {:ok, deleted} = Rivet.Data.Ident.Factor.delete(model)
      assert deleted.id == model.id
    end
  end
end
