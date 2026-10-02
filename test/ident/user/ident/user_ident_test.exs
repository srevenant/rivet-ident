defmodule Rivet.Ident.Test.UserIdentTest do
  use Rivet.Ident.Case, async: true
  alias Rivet.Ident.UserIdent

  test "model tests" do
    assert %UserIdent{ident} = insert(:ident_user_ident)
    # assert is_uuid(id)
    assert %UserIdent{ident: ^ident} = UserIdent.one!(ident: ident)
    params = params_with_assocs(:ident_user_ident)
    assert {:ok, %UserIdent{}} = UserIdent.create(params)
  end
end
