defmodule Rivet.Data.Ident.Test.PhoneTest do
  use Rivet.Data.Ident.Case, async: true

  doctest Rivet.Data.Ident.Phone, import: true
  doctest Rivet.Data.Ident.Phone.Db, import: true
  doctest Rivet.Data.Ident.Phone.Loader, import: true
  doctest Rivet.Data.Ident.Phone.Seeds, import: true
  doctest Rivet.Data.Ident.Phone.Graphql, import: true
  doctest Rivet.Data.Ident.Phone.Resolver, import: true
  doctest Rivet.Data.Ident.Phone.Rest, import: true
  doctest Rivet.Data.Ident.Phone.Cache, import: true

  describe "factory" do
    test "factory creates a valid instance" do
      assert %{} = model = insert(:ident_phone)
      assert model.id != nil
    end
  end

  describe "build/1" do
    test "build when valid" do
      params = params_with_assocs(:ident_phone)
      changeset = Rivet.Data.Ident.Phone.build(params)
      assert changeset.valid?
    end
  end

  describe "get/1" do
    test "loads saved transactions as expected" do
      c = insert(:ident_phone)
      assert %Rivet.Data.Ident.Phone{} = found = Rivet.Data.Ident.Phone.one!(id: c.id)
      assert found.id == c.id
    end
  end

  describe "create/1" do
    test "inserts a valid record" do
      attrs = params_with_assocs(:ident_phone)
      assert {:ok, model} = Rivet.Data.Ident.Phone.create(attrs)
      assert model.id != nil
    end
  end

  describe "delete/1" do
    test "deletes record" do
      model = insert(:ident_phone)
      assert {:ok, deleted} = Rivet.Data.Ident.Phone.delete(model)
      assert deleted.id == model.id
    end
  end
end
