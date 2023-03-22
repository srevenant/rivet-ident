defmodule Rivet.Ident.Test.ActionTest do
  use Rivet.Ident.Case, async: true

  doctest Rivet.Ident.Action, import: true
  doctest Rivet.Ident.Action.Lib, import: true
  doctest Rivet.Ident.Action.Loader, import: true
  doctest Rivet.Ident.Action.Seeds, import: true
  
  
  doctest Rivet.Ident.Action.Rest, import: true
  doctest Rivet.Ident.Action.Cache, import: true

  describe "factory" do
    test "factory creates a valid instance" do
      assert %{} = model = insert(:ident_action)
      assert model.id != nil
    end
  end

  describe "build/1" do
    test "build when valid" do
      params = params_with_assocs(:ident_action)
      changeset = Rivet.Ident.Action.build(params)
      assert changeset.valid?
    end
  end

  describe "get/1" do
    test "loads saved transactions as expected" do
      c = insert(:ident_action)
      assert %Rivet.Ident.Action{} = found = Rivet.Ident.Action.one!(id: c.id)
      assert found.id == c.id
    end
  end

  describe "create/1" do
    test "inserts a valid record" do
      attrs = params_with_assocs(:ident_action)
      assert {:ok, model} = Rivet.Ident.Action.create(attrs)
      assert model.id != nil
    end
  end

  describe "delete/1" do
    test "deletes record" do
      model = insert(:ident_action)
      assert {:ok, deleted} = Rivet.Ident.Action.delete(model)
      assert deleted.id == model.id
    end
  end
end
