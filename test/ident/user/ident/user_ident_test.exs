defmodule Rivet.Ident.Test.UserIdentTest do
  use Rivet.Ident.Case, async: true

  doctest Rivet.Ident.UserIdent, import: true
  doctest Rivet.Ident.UserIdent.Lib, import: true

  describe "factory" do
    test "factory creates a valid instance" do
      assert %{} = model = insert(:ident_user_ident)
      assert model.ident != nil
    end
  end

  describe "build/1" do
    test "build when valid" do
      params = params_with_assocs(:ident_user_ident)
      changeset = Rivet.Ident.UserIdent.build(params)
      assert changeset.valid?
    end
  end

  describe "get/1" do
    test "loads saved transactions as expected" do
      c = insert(:ident_user_ident)

      assert %Rivet.Ident.UserIdent{} = found = Rivet.Ident.UserIdent.one!(ident: c.ident)

      assert found.ident == c.ident
    end
  end

  describe "create/1" do
    test "inserts a valid record" do
      attrs = params_with_assocs(:ident_user_ident)
      assert {:ok, model} = Rivet.Ident.UserIdent.create(attrs)
      assert model.ident != nil
    end
  end

  describe "delete_all/2" do
    test "deletes record" do
      %{ident: ident, origin: origin} = insert(:ident_user_ident)

      assert {num, nil} =
               [ident: ident, origin: origin]
               |> Rivet.Ident.UserIdent.delete_all()

      assert num > 0
    end
  end
end
