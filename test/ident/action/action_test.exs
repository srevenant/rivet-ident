defmodule Rivet.Data.Ident.Test.ActionTest do
  use Rivet.Data.Ident.Case, async: true

  doctest Rivet.Data.Ident.Action, import: true
  doctest Rivet.Data.Ident.Action.Lib, import: true
  doctest Rivet.Data.Ident.Action.Loader, import: true
  doctest Rivet.Data.Ident.Action.Seeds, import: true
  doctest Rivet.Data.Ident.Action.Graphql, import: true
  doctest Rivet.Data.Ident.Action.Resolver, import: true
  doctest Rivet.Data.Ident.Action.Rest, import: true
  doctest Rivet.Data.Ident.Action.Cache, import: true

  describe "factory" do
    test "factory creates a valid instance" do
      assert %{} = model = insert(:ident_action)
      assert model.id != nil
    end
  end

  describe "build/1" do
    test "build when valid" do
      params = params_with_assocs(:ident_action)
      changeset = Rivet.Data.Ident.Action.build(params)
      assert changeset.valid?
    end
  end

  describe "get/1" do
    test "loads saved transactions as expected" do
      c = insert(:ident_action)
      assert %Rivet.Data.Ident.Action{} = found = Rivet.Data.Ident.Action.one!(id: c.id)
      assert found.id == c.id
    end
  end

  describe "create/1" do
    test "inserts a valid record" do
      attrs = params_with_assocs(:ident_action)
      assert {:ok, model} = Rivet.Data.Ident.Action.create(attrs)
      assert model.id != nil
    end
  end

  describe "delete/1" do
    test "deletes record" do
      model = insert(:ident_action)
      assert {:ok, deleted} = Rivet.Data.Ident.Action.delete(model)
      assert deleted.id == model.id
    end
  end
end
