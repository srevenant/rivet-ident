defmodule Rivet.Ident.Test.Ident.User.CacheTest do
  use Rivet.Ident.Support.Case, async: true

  test "cache" do
    %{id} = insert(:ident_user)
    # miss
    assert {:ok, %{id: ^id}} = User.Cache.get_user(id)
    # hit
    assert {:ok, %{id: ^id}} = User.Cache.get_user(id)
  end
end
