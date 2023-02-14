defmodule Rivet.Data.Ident.Test.EmailTest do
  use Rivet.Data.Ident.Case, async: true

  doctest Rivet.Data.Ident.Email, import: true
  doctest Rivet.Data.Ident.Email.Db, import: true
  doctest Rivet.Data.Ident.Email.Loader, import: true
  doctest Rivet.Data.Ident.Email.Seeds, import: true
  doctest Rivet.Data.Ident.Email.Graphql, import: true
  doctest Rivet.Data.Ident.Email.Resolver, import: true
  doctest Rivet.Data.Ident.Email.Rest, import: true
  doctest Rivet.Data.Ident.Email.Cache, import: true

  describe "factory" do
    test "factory creates a valid instance" do
      assert %{} = model = insert(:email)
      assert model.id != nil
    end
  end

  describe "build/1" do
    test "build when valid" do
      params = params_with_assocs(:email)
      changeset = Rivet.Data.Ident.Email.build(params)
      assert changeset.valid?
    end
  end

  describe "get/1" do
    test "loads saved transactions as expected" do
      c = insert(:email)
      assert %Rivet.Data.Ident.Email{} = found = Rivet.Data.Ident.Email.one!(id: c.id)
      assert found.id == c.id
    end
  end

  describe "create/1" do
    test "inserts a valid record" do
      attrs = params_with_assocs(:email)
      assert {:ok, model} = Rivet.Data.Ident.Email.create(attrs)
      assert model.id != nil
    end
  end

  describe "delete/1" do
    test "deletes record" do
      model = insert(:email)
      assert {:ok, deleted} = Rivet.Data.Ident.Email.delete(model)
      assert deleted.id == model.id
    end
  end
end
