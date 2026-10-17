defmodule Rivet.Ident.Test.Ident.User.DataTest do
  use Rivet.Ident.Test.Case, async: true
  alias Rivet.Ident.User.Data

  test "model tests" do
    assert %Data{id} = insert(:ident_user_data)
    assert is_uuid(id)
    assert %Data{id: ^id} = Data.one!(id: id)
    params = params_with_assocs(:ident_user_data)
    assert {:ok, %Data{} = x} = Data.create(params)
    assert {:ok, _} = Data.delete(x)
  end
end
