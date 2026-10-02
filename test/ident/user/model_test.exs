defmodule Rivet.Ident.Test.UserTest do
  use Rivet.Ident.Case, async: true

  doctest Rivet.Ident.User, import: true
  doctest Rivet.Ident.User.Lib, import: true
  doctest Rivet.Ident.User.Cache, import: true

  test "Model" do
    attrs = params_with_assocs(:user)
    assert %{valid?: true} = User.build(attrs)
    assert {:ok, %{id: user_id} = user} = User.create(attrs)
    assert %User{id: ^user_id} = User.one!(id: user.id)
    # first is for the cache miss
    assert {:ok, _} = Core.Auth.Cache.get_authz(user)
    # second is for the cache hit
    assert {:ok, _} = Core.Auth.Cache.get_authz(user)
    assert {:ok, %{id: ^user_id}} = User.delete(user)
  end
end
