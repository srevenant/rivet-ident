defmodule Rivet.Ident.Test.Ident.User.LibTest do
  use Rivet.Ident.Test.Case, async: true
  use Rivet.Ident
  alias Rivet.Auth

  doctest User.Lib, import: true

  test "various ~ coverage" do
    uuid = Ecto.UUID.generate()
    assert [] = User.Lib.search_name!(uuid)
    assert [] = User.Lib.all_since(DateTime.utc_now())

    assert User.Code.type!(:email_verify)
    assert User.Code.type!(:delete_request)

    disabled = build(:ident_user, type: :disabled)

    assert User.enabled?(build(:ident_user))
    refute User.enabled?(disabled)

    errmsg = "sorry, account is disabled"

    assert {:error, %Auth.Domain{error: ^errmsg}} =
             User.Lib.check_user_status(%Auth.Domain{user: disabled})

    assert {:error, %Auth.Domain{error: ^errmsg}} = User.Lib.check_user_status(disabled)
    assert {:ok, _} = User.Lib.check_user_status(build(:ident_user))

    # get with no preload default
    %{user: %{id} = user} = handle = insert(:ident_handle)
    assert {:ok, %User{id: ^id}} = User.Lib.get_user_by_handle(handle.handle)

    # passthrough check_user_status
    assert {:ok, %Auth.Domain{error: "boo"}} =
             User.Lib.check_user_status(%Auth.Domain{error: "boo"})

    # nope
    assert {:error, "Cannot email verify because user" <> _} = User.Lib.send_verify_email(user)
  end

  test "seen" do
    user = insert(:ident_user)
    user_id = user.id
    assert %{id: ^user_id} = user = User.Lib.user_seen(user)
    assert %{id: ^user_id} = User.Lib.user_seen(user)
  end

  test "with_user" do
    %{id} = user = insert(:ident_user)

    assert {:ok, ^id} =
             User.Lib.with_user(user, [:emails], fn u ->
               assert is_list(u.emails)
               {:ok, u.id}
             end)

    assert {:ok, ^id} = User.Lib.with_user(id, [], fn u -> {:ok, u.id} end)

    assert {:error, :not_found} =
             User.Lib.with_user(Ecto.UUID.generate(), [], fn _ -> flunk("unexpected user") end)
  end

  test "cannot add email belonging to another user" do
    user1 = insert(:ident_user)
    user2 = insert(:ident_user)
    address = "test-#{Ecto.UUID.generate()}@example.com"

    assert {:ok, %{id}} = User.Lib.add_email(user1, address)
    assert {:ok, %{id: ^id}} = User.Lib.add_email(user1, address)

    assert {:error, "Sorry, that email address is associated with a different account."} =
             User.Lib.add_email(user2, address)

    assert {:ok, %{user_id: user_id}} = Email.one(address: address)
    assert user_id == user1.id
  end

  test "delete account" do
    %{user: user} = handle = insert(:ident_handle)
    user_id = user.id
    address = "delete-#{Ecto.UUID.generate()}@example.com"
    ext_key = Ecto.UUID.generate()

    {:ok, email} = User.Lib.add_email(user, address)
    {:ok, phone} = User.Lib.add_phone(user, "+18015551234")
    {:ok, _} = User.ExtId.Lib.put(user, "test", ext_key)

    {:ok, wrong_type} = User.Code.Lib.generate_code(user_id, :email_verify, 10)
    {:ok, expired} = User.Code.Lib.generate_code(user_id, :delete_request, -1)
    {:ok, valid} = User.Code.Lib.generate_code(user_id, :delete_request, 10)

    assert {:error, "Unable to continue"} = User.Lib.delete_account(user, wrong_type.code)
    assert {:error, "Unable to continue"} = User.Lib.delete_account(user, expired.code)
    assert {:error, "Unable to continue"} = User.Lib.delete_account(user, "invalid")

    assert {:ok, %User{id: ^user_id}} = User.Lib.delete_account(user, valid.code)

    # Base user is retained but sanitized/disabled
    assert {:ok, %User{name: "DELETED", type: :disabled}} = User.one(id: user_id)

    # Personal identifiers are removed
    assert {:error, :not_found} = Email.one(id: email.id)
    assert {:error, :not_found} = Ident.Phone.one(id: phone.id)
    assert {:error, :not_found} = Handle.one(handle: handle.handle)
    assert {:error, :not_found} = User.ExtId.one(origin: "test", extid: ext_key)
  end
end
