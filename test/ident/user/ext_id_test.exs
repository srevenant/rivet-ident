defmodule Rivet.Ident.Test.Ident.User.ExtIdTest do
  use Rivet.Ident.Test.Case, async: true
  alias Rivet.Ident.User.ExtId

  test "model tests" do
    assert %ExtId{extid} = insert(:ident_user_extid)
    # assert is_uuid(id)
    assert %ExtId{extid: ^extid} = ExtId.one!(extid: extid)
    params = params_with_assocs(:ident_user_extid)
    assert {:ok, %ExtId{}} = ExtId.create(params)
  end
end
