defmodule Rivet.Data.Ident.Test.UserTest do
  use Rivet.Data.Ident.Case, async: true

  doctest Rivet.Data.Ident.User, import: true
  doctest Rivet.Data.Ident.User.Db, import: true
  doctest Rivet.Data.Ident.User.Loader, import: true
  doctest Rivet.Data.Ident.User.Seeds, import: true
  doctest Rivet.Data.Ident.User.Graphql, import: true
  doctest Rivet.Data.Ident.User.Resolver, import: true
  doctest Rivet.Data.Ident.User.Rest, import: true
  doctest Rivet.Data.Ident.User.Cache, import: true

  describe "factory" do
    test "factory creates a valid instance" do
      assert %{} = model = insert(:user)
      assert model.id != nil
    end
  end

  describe "build/1" do
    test "build when valid" do
      params = params_with_assocs(:user)
      changeset = Rivet.Data.Ident.User.build(params)
      assert changeset.valid?
    end
  end

  describe "get/1" do
    test "loads saved transactions as expected" do
      c = insert(:user)
      assert %Rivet.Data.Ident.User{} = found = Rivet.Data.Ident.User.one!(id: c.id)
      assert found.id == c.id
    end
  end

  describe "create/1" do
    test "inserts a valid record" do
      attrs = params_with_assocs(:user)
      assert {:ok, model} = Rivet.Data.Ident.User.create(attrs)
      assert model.id != nil
    end
  end

  describe "delete/1" do
    test "deletes record" do
      model = insert(:user)
      assert {:ok, deleted} = Rivet.Data.Ident.User.delete(model)
      assert deleted.id == model.id
    end
  end
end
