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
    origin = "google"
    ext_id = Ecto.UUID.generate()

    assert {:ok, _} = ExtId.Lib.put(user, origin, ext_id)

    assert {:error, "ExtId exists"} =
             ExtId.Lib.put(%{user | id: Ecto.UUID.generate()}, origin, ext_id)

    assert {:ok, %{user_id: ^user_id, origin: ^origin, extid: ^ext_id}} =
             ExtId.Lib.get(origin, ext_id)

    # mis-matched
    assert {:error, :not_found} = ExtId.Lib.get("github", ext_id)
    assert {:error, :not_found} = ExtId.Lib.get(origin, "unknown")
  end
end
