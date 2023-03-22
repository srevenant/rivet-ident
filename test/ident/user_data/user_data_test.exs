defmodule Rivet.Ident.Test.UserDataTest do
  use Rivet.Ident.Case, async: true

  doctest Rivet.Ident.UserData, import: true
  doctest Rivet.Ident.UserData.Lib, import: true
  doctest Rivet.Ident.UserData.Loader, import: true
  doctest Rivet.Ident.UserData.Seeds, import: true
  
  
  doctest Rivet.Ident.UserData.Rest, import: true
  doctest Rivet.Ident.UserData.Cache, import: true

  describe "factory" do
    test "factory creates a valid instance" do
      assert %{} = model = insert(:ident_user_data)
      assert model.id != nil
    end
  end

  describe "build/1" do
    test "build when valid" do
      params = params_with_assocs(:ident_user_data)
      changeset = Rivet.Ident.UserData.build(params)
      assert changeset.valid?
    end
  end

  describe "get/1" do
    test "loads saved transactions as expected" do
      c = insert(:ident_user_data)
      assert %Rivet.Ident.UserData{} = found = Rivet.Ident.UserData.one!(id: c.id)
      assert found.id == c.id
    end
  end

  describe "create/1" do
    test "inserts a valid record" do
      attrs = params_with_assocs(:ident_user_data)
      assert {:ok, model} = Rivet.Ident.UserData.create(attrs)
      assert model.id != nil
    end
  end

  describe "delete/1" do
    test "deletes record" do
      model = insert(:ident_user_data)
      assert {:ok, deleted} = Rivet.Ident.UserData.delete(model)
      assert deleted.id == model.id
    end
  end
end
