defmodule Rivet.Ident.Test.Ident.User.LibTest do
  use Rivet.Ident.Test.Case, async: true
  use Rivet.Ident
  alias Rivet.Auth

  doctest User.Lib, import: true

  test "search" do
    name = "RICHTHOFEN"
    user = insert(:ident_user, name: name)
    insert(:ident_handle, user: user)
    insert(:ident_email, user: user)

    assert {:ok, [%Rivet.Ident.User{name: ^name}]} =
             Rivet.Ident.User.Lib.search(%{matching: String.downcase(name)}, [])
  end

  test "various" do
    uuid = Ecto.UUID.generate()
    assert [] = User.Lib.search_name!(uuid)
    assert [] = User.Lib.all_since(DateTime.utc_now())

    disabled = build(:ident_user, type: :disabled)
    assert true == User.Lib.user_enabled?(build(:ident_user))
    assert false == User.Lib.user_enabled?(disabled)
    errmsg = "sorry, account is disabled"

    assert {:error, %{error: ^errmsg}} =
             User.Lib.check_user_status({:ok, %Auth.Domain{user: disabled}})

    assert {:error, %{error: ^errmsg}} = User.Lib.check_user_status(disabled)
    assert {:ok, _} = User.Lib.check_user_status(build(:ident_user))
  end

  test "seen" do
    user = insert(:ident_user)
    user_id = user.id
    assert %{id: ^user_id} = user = User.Lib.user_seen(user)
    assert %{id: ^user_id} = User.Lib.user_seen(user)
  end
end
