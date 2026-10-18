defmodule Rivet.Ident.Test.Ident.User.ExtIdTest do
  use Rivet.Ident.Support.Case, async: true
  alias Rivet.Ident.User.ExtId

  test "model tests" do
    assert %ExtId{extid} = insert(:ident_user_extid)
    assert %ExtId{extid: ^extid} = ExtId.one!(extid: extid)
    params = params_with_assocs(:ident_user_extid)
    assert {:ok, %ExtId{}} = ExtId.create(params)
  end

  test "put and get external ID" do
    %{id: user_id} = user = insert(:ident_user)

    assert {:ok, _} = ExtId.Lib.put(user, "google", "abc123")
    assert {:ok, extid} = ExtId.Lib.get("google", "abc123")
    assert extid.user_id == user_id
    assert extid.origin == "google"
    assert extid.extid == "abc123"

    # Both origin and external ID must match
    assert :error = ExtId.Lib.get("github", "abc123")
    assert :error = ExtId.Lib.get("google", "unknown")
  end

  test "put replaces existing mapping" do
    user1 = insert(:ident_user)
    user2 = insert(:ident_user)

    assert {:ok, _} = ExtId.Lib.put(user1, "google", "abc123")
    assert {:ok, %{user_id: user_id}} = ExtId.Lib.get("google", "abc123")
    assert user_id == user1.id

    # Same external identity gets reassigned to another user
    assert {:ok, _} = ExtId.Lib.put(user2, "google", "abc123")
    assert {:ok, %{user_id: user_id}} = ExtId.Lib.get("google", "abc123")
    assert user_id == user2.id
  end
end
