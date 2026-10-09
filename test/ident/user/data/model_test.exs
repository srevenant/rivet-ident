defmodule Rivet.Ident.Test.Ident.User.Data.ModelTest do
  use Rivet.Ident.Test.Support.Case, async: true
  alias Rivet.Ident.User.Data

  test "model tests" do
    assert %User.Data{id} = insert(:ident_user_data)
    assert is_uuid(id)
    assert %User.Data{id: ^id} = User.Data.one!(id: id)
    params = params_with_assocs(:ident_user_data)
    assert {:ok, %User.Data{} = x} = User.Data.create(params)
    assert {:ok, _} = User.Data.delete(x)
  end
end
