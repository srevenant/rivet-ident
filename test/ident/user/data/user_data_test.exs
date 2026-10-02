defmodule Rivet.Ident.Test.UserDataTest do
  use Rivet.Ident.Case, async: true
  alias Rivet.Ident.UserData

  test "model tests" do
    assert %UserData{id} = insert(:ident_user_data)
    assert is_uuid(id)
    assert %UserData{id: ^id} = UserData.one!(id: id)
    params = params_with_assocs(:ident_user_data)
    assert {:ok, %UserData{} = x} = UserData.create(params)
    assert {:ok, _} = UserData.delete(x)
  end
end
