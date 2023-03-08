defmodule Rivet.Ident.Test.UserCodeTest do
  use Rivet.Ident.Case, async: true

  doctest Rivet.Ident.UserCode, import: true
  doctest Rivet.Ident.UserCode.Lib, import: true
  doctest Rivet.Ident.UserCode.Loader, import: true
  doctest Rivet.Ident.UserCode.Seeds, import: true
  doctest Rivet.Ident.UserCode.Graphql, import: true
  doctest Rivet.Ident.UserCode.Resolver, import: true
  doctest Rivet.Ident.UserCode.Rest, import: true
  doctest Rivet.Ident.UserCode.Cache, import: true

  describe "factory" do
    test "factory creates a valid instance" do
      assert %{} = model = insert(:ident_user_code)
      assert model.id != nil
    end
  end

  describe "build/1" do
    test "build when valid" do
      params = params_with_assocs(:ident_user_code)
      changeset = Rivet.Ident.UserCode.build(params)
      assert changeset.valid?
    end
  end

  describe "get/1" do
    test "loads saved transactions as expected" do
      c = insert(:ident_user_code)
      assert %Rivet.Ident.UserCode{} = found = Rivet.Ident.UserCode.one!(id: c.id)
      assert found.id == c.id
    end
  end

  describe "create/1" do
    test "inserts a valid record" do
      attrs = params_with_assocs(:ident_user_code)
      assert {:ok, model} = Rivet.Ident.UserCode.create(attrs)
      assert model.id != nil
    end
  end

  describe "delete/1" do
    test "deletes record" do
      model = insert(:ident_user_code)
      assert {:ok, deleted} = Rivet.Ident.UserCode.delete(model)
      assert deleted.id == model.id
    end
  end
end
