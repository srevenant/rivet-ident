defmodule Rivet.Data.Ident.Test.UserDataTest do
  use Rivet.Data.Ident.Case, async: true

  doctest Rivet.Data.Ident.UserData, import: true
  doctest Rivet.Data.Ident.UserData.Db, import: true
  doctest Rivet.Data.Ident.UserData.Loader, import: true
  doctest Rivet.Data.Ident.UserData.Seeds, import: true
  doctest Rivet.Data.Ident.UserData.Graphql, import: true
  doctest Rivet.Data.Ident.UserData.Resolver, import: true
  doctest Rivet.Data.Ident.UserData.Rest, import: true
  doctest Rivet.Data.Ident.UserData.Cache, import: true

  describe "factory" do
    test "factory creates a valid instance" do
      assert %{} = model = insert(:ident_user_data)
      assert model.id != nil
    end
  end

  describe "build/1" do
    test "build when valid" do
      params = params_with_assocs(:ident_user_data)
      changeset = Rivet.Data.Ident.UserData.build(params)
      assert changeset.valid?
    end
  end

  describe "get/1" do
    test "loads saved transactions as expected" do
      c = insert(:ident_user_data)
      assert %Rivet.Data.Ident.UserData{} = found = Rivet.Data.Ident.UserData.one!(id: c.id)
      assert found.id == c.id
    end
  end

  describe "create/1" do
    test "inserts a valid record" do
      attrs = params_with_assocs(:ident_user_data)
      assert {:ok, model} = Rivet.Data.Ident.UserData.create(attrs)
      assert model.id != nil
    end
  end

  describe "delete/1" do
    test "deletes record" do
      model = insert(:ident_user_data)
      assert {:ok, deleted} = Rivet.Data.Ident.UserData.delete(model)
      assert deleted.id == model.id
    end
  end
end
