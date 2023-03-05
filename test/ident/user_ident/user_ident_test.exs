defmodule Rivet.Data.Ident.Test.UserIdentTest do
  use Rivet.Data.Ident.Case, async: true

  doctest Rivet.Data.Ident.UserIdent, import: true
  doctest Rivet.Data.Ident.UserIdent.Lib, import: true
  doctest Rivet.Data.Ident.UserIdent.Loader, import: true
  doctest Rivet.Data.Ident.UserIdent.Seeds, import: true
  doctest Rivet.Data.Ident.UserIdent.Graphql, import: true
  doctest Rivet.Data.Ident.UserIdent.Resolver, import: true
  doctest Rivet.Data.Ident.UserIdent.Rest, import: true
  doctest Rivet.Data.Ident.UserIdent.Cache, import: true

  describe "factory" do
    test "factory creates a valid instance" do
      assert %{} = model = insert(:ident_user_ident)
      assert model.ident != nil
    end
  end

  describe "build/1" do
    test "build when valid" do
      params = params_with_assocs(:ident_user_ident)
      changeset = Rivet.Data.Ident.UserIdent.build(params)
      assert changeset.valid?
    end
  end

  describe "get/1" do
    test "loads saved transactions as expected" do
      c = insert(:ident_user_ident)

      assert %Rivet.Data.Ident.UserIdent{} =
               found = Rivet.Data.Ident.UserIdent.one!(ident: c.ident)

      assert found.ident == c.ident
    end
  end

  describe "create/1" do
    test "inserts a valid record" do
      attrs = params_with_assocs(:ident_user_ident)
      assert {:ok, model} = Rivet.Data.Ident.UserIdent.create(attrs)
      assert model.ident != nil
    end
  end

  describe "delete_all/2" do
    test "deletes record" do
      %{ident: ident, origin: origin} = insert(:ident_user_ident)

      assert {num, nil} =
               [ident: ident, origin: origin]
               |> Rivet.Data.Ident.UserIdent.delete_all()

      assert num > 0
    end
  end
end
