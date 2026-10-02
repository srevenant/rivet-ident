defmodule Rivet.Ident.Test.PhoneTest do
  use Rivet.Ident.Case, async: true
  alias Rivet.Ident.Phone

  test "model tests" do
    assert %Phone{id} = insert(:ident_phone)
    assert is_uuid(id)
    assert %Phone{id: ^id} = Phone.one!(id: id)
    params = params_with_assocs(:ident_phone)
    assert {:ok, %Phone{} = x} = Phone.create(params)
    assert {:ok, _} = Phone.delete(x)
  end

end
