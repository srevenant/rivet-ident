defmodule Rivet.Ident.Test.Ident.Factor.ModelTest do
  use Rivet.Ident.Support.Case, async: true
  alias Rivet.Ident.Factor

  test "model tests" do
    assert %Factor{id} = insert(:ident_factor)
    assert is_uuid(id)
    assert %Factor{id: ^id} = Factor.one!(id: id)
    params = params_with_assocs(:ident_factor)
    assert {:ok, %Factor{} = x} = Factor.create(params)
    assert {:ok, _} = Factor.delete(x)
  end

  test "preloaded_with" do
    # insert an extra that isn't ours
    insert(:ident_factor, type: :password)

    # insert ours
    %{user: user, id: f_id} = insert(:ident_factor, type: :password)

    assert %User{factors: [%Factor{id: ^f_id}]} = Factor.Lib.preloaded_with(user, :password)
  end

  test "cache" do
    factor = %{user} = insert(:ident_factor)
    assert {:ok, _} = Factor.Cache.persist(factor)
    assert :ok == Factor.Cache.update_user(%{user | state: %{active_factor_id: Ecto.UUID.generate()}})
  end
end
