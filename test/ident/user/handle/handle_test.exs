defmodule Rivet.Ident.Test.HandleTest do
  use Rivet.Ident.Case, async: true
  alias Rivet.Ident.Handle

  test "model tests" do
    assert %Handle{id} = insert(:ident_handle)
    assert is_uuid(id)
    assert %Handle{id: ^id} = Handle.one!(id: id)
    params = params_with_assocs(:ident_handle)
    assert {:ok, %Handle{} = x} = Handle.create(params)
    assert {:ok, _} = Handle.delete(x)
  end
end
