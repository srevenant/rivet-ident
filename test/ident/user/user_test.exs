defmodule Rivet.Ident.Test.UserTest do
  use Rivet.Ident.Case, async: true

  doctest Rivet.Ident.User, import: true
  doctest Rivet.Ident.User.Lib, import: true
  doctest Rivet.Ident.User.Loader, import: true
  doctest Rivet.Ident.User.Seeds, import: true
  doctest Rivet.Ident.User.Graphql, import: true
  doctest Rivet.Ident.User.Resolver, import: true
  doctest Rivet.Ident.User.Rest, import: true
  doctest Rivet.Ident.User.Cache, import: true

  describe "factory" do
    test "factory creates a valid instance" do
      assert %{} = model = insert(:ident_user)
      assert model.id != nil
    end
  end

  describe "build/1" do
    test "build when valid" do
      params = params_with_assocs(:ident_user)
      changeset = Rivet.Ident.User.build(params)
      assert changeset.valid?
    end
  end

  describe "get/1" do
    test "loads saved transactions as expected" do
      c = insert(:ident_user)
      assert %Rivet.Ident.User{} = found = Rivet.Ident.User.one!(id: c.id)
      assert found.id == c.id
    end
  end

  describe "create/1" do
    test "inserts a valid record" do
      attrs = params_with_assocs(:ident_user)
      assert {:ok, model} = Rivet.Ident.User.create(attrs)
      assert model.id != nil
    end
  end

  describe "delete/1" do
    test "deletes record" do
      model = insert(:ident_user)
      assert {:ok, deleted} = Rivet.Ident.User.delete(model)
      assert deleted.id == model.id
    end
  end
end
