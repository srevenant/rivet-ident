defmodule Rivet.Ident.Test.FactorTest do
  use Rivet.Ident.Case, async: true

  doctest Rivet.Ident.Factor, import: true
  doctest Rivet.Ident.Factor.Lib, import: true
  doctest Rivet.Ident.Factor.Loader, import: true
  doctest Rivet.Ident.Factor.Seeds, import: true
  
  
  doctest Rivet.Ident.Factor.Rest, import: true
  doctest Rivet.Ident.Factor.Cache, import: true

  describe "factory" do
    test "factory creates a valid instance" do
      assert %{} = model = insert(:ident_factor)
      assert model.id != nil
    end
  end

  describe "build/1" do
    test "build when valid" do
      params = params_with_assocs(:ident_factor)
      changeset = Rivet.Ident.Factor.build(params)
      assert changeset.valid?
    end
  end

  describe "get/1" do
    test "loads saved transactions as expected" do
      c = insert(:ident_factor)
      assert %Rivet.Ident.Factor{} = found = Rivet.Ident.Factor.one!(id: c.id)
      assert found.id == c.id
    end
  end

  describe "create/1" do
    test "inserts a valid record" do
      attrs = params_with_assocs(:ident_factor)
      assert {:ok, model} = Rivet.Ident.Factor.create(attrs)
      assert model.id != nil
    end
  end

  describe "delete/1" do
    test "deletes record" do
      model = insert(:ident_factor)
      assert {:ok, deleted} = Rivet.Ident.Factor.delete(model)
      assert deleted.id == model.id
    end
  end
end
