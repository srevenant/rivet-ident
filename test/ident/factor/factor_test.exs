defmodule Rivet.Ident.Test.FactorTest do
  alias Rivet.Ident
  use Ident.Case, async: true

  doctest Ident.Factor, import: true
  doctest Ident.Factor.Lib, import: true
  doctest Ident.Factor.Loader, import: true
  doctest Ident.Factor.Seeds, import: true


  doctest Ident.Factor.Rest, import: true
  doctest Ident.Factor.Cache, import: true

  describe "factory" do
    test "factory creates a valid instance" do
      assert %{} = model = insert(:ident_factor)
      assert model.id != nil
    end
  end

  describe "build/1" do
    test "build when valid" do
      params = params_with_assocs(:ident_factor)
      changeset = Ident.Factor.build(params)
      assert changeset.valid?
    end
  end

  describe "get/1" do
    test "loads saved transactions as expected" do
      c = insert(:ident_factor)
      assert %Ident.Factor{} = found = Ident.Factor.one!(id: c.id)
      assert found.id == c.id
    end
  end

  describe "create/1" do
    test "inserts a valid record" do
      attrs = params_with_assocs(:ident_factor)
      assert {:ok, model} = Ident.Factor.create(attrs)
      assert model.id != nil
    end
  end

  describe "delete/1" do
    test "deletes record" do
      model = insert(:ident_factor)
      assert {:ok, deleted} = Ident.Factor.delete(model)
      assert deleted.id == model.id
    end
  end

  describe "preload_with" do
    test "properly preloads" do
      # insert an extra that isn't ours
      insert(:ident_factor, type: :password)

      # insert ours
      %{user: user, id: f_id} = insert(:ident_factor, type: :password)

      assert %Ident.User{factors: [%Ident.Factor{id: ^f_id}]} = Ident.Factor.Lib.preloaded_with(user, :password)
    end
  end
end
