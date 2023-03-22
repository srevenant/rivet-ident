defmodule Rivet.Ident.Test.HandleTest do
  use Rivet.Ident.Case, async: true

  doctest Rivet.Ident.Handle, import: true
  doctest Rivet.Ident.Handle.Lib, import: true
  doctest Rivet.Ident.Handle.Loader, import: true
  doctest Rivet.Ident.Handle.Seeds, import: true
  
  
  doctest Rivet.Ident.Handle.Rest, import: true
  doctest Rivet.Ident.Handle.Cache, import: true

  describe "factory" do
    test "factory creates a valid instance" do
      assert %{} = model = insert(:ident_handle)
      assert model.id != nil
    end
  end

  describe "build/1" do
    test "build when valid" do
      params = params_with_assocs(:ident_handle)
      changeset = Rivet.Ident.Handle.build(params)
      assert changeset.valid?
    end
  end

  describe "get/1" do
    test "loads saved transactions as expected" do
      c = insert(:ident_handle)
      assert %Rivet.Ident.Handle{} = found = Rivet.Ident.Handle.one!(id: c.id)
      assert found.id == c.id
    end
  end

  describe "create/1" do
    test "inserts a valid record" do
      attrs = params_with_assocs(:ident_handle)
      assert {:ok, model} = Rivet.Ident.Handle.create(attrs)
      assert model.id != nil
    end
  end

  describe "delete/1" do
    test "deletes record" do
      model = insert(:ident_handle)
      assert {:ok, deleted} = Rivet.Ident.Handle.delete(model)
      assert deleted.id == model.id
    end
  end
end
