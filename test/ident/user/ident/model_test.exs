defmodule Rivet.Ident.Test.Ident.User.Ident.ModelTest do
  use Rivet.Ident.Test.Case, async: true
  alias Rivet.Ident.User.ExtId

  test "model tests" do
    assert %User.ExtId{extid} = insert(:ident_user_extid)
    # assert is_uuid(id)
    assert %User.ExtId{extid: ^extid} = User.ExtId.one!(extid: extid)
    params = params_with_assocs(:ident_user_extid)
    assert {:ok, %User.ExtId{}} = User.ExtId.create(params)
  end
end
