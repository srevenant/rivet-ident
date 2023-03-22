defmodule Rivet.Ident.Test.EmailTest do
  use Rivet.Ident.Case, async: true

  doctest Rivet.Ident.Email, import: true
  doctest Rivet.Ident.Email.Lib, import: true
  doctest Rivet.Ident.Email.Loader, import: true
  doctest Rivet.Ident.Email.Seeds, import: true
  
  
  doctest Rivet.Ident.Email.Rest, import: true
  doctest Rivet.Ident.Email.Cache, import: true

  describe "factory" do
    test "factory creates a valid instance" do
      assert %{} = model = insert(:ident_email)
      assert model.id != nil
    end
  end

  describe "build/1" do
    test "build when valid" do
      params = params_with_assocs(:ident_email)
      changeset = Rivet.Ident.Email.build(params)
      assert changeset.valid?
    end
  end

  describe "get/1" do
    test "loads saved transactions as expected" do
      c = insert(:ident_email)
      assert %Rivet.Ident.Email{} = found = Rivet.Ident.Email.one!(id: c.id)
      assert found.id == c.id
    end
  end

  describe "create/1" do
    test "inserts a valid record" do
      attrs = params_with_assocs(:ident_email)
      assert {:ok, model} = Rivet.Ident.Email.create(attrs)
      assert model.id != nil
    end
  end

  describe "delete/1" do
    test "deletes record" do
      model = insert(:ident_email)
      assert {:ok, deleted} = Rivet.Ident.Email.delete(model)
      assert deleted.id == model.id
    end
  end
end
