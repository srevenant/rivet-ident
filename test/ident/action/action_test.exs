defmodule Rivet.Ident.Test.ActionTest do
  use Rivet.Ident.Case
  alias Rivet.Ident.Action

  test "model tests" do
    assert %Action{id} = insert(:ident_action)
    assert is_integer(id)
    assert %Action{id: ^id} = Action.one!(id: id)
    params = params_with_assocs(:ident_action)
    assert {:ok, %Action{} = x} = Action.create(params)
    assert {:ok, _} = Action.delete(x)
  end
end
