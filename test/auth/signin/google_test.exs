defmodule Rivet.Ident.Test.Auth.GoogleTest do
  use Rivet.Ident.Support.Case
  use Rivet.Ident
  alias Rivet.Auth
  alias Rivet.Auth.Signin.Google

  @failed_error "Signup failed. Perhaps try password recovery?"

  test "Google" do
    assert {:error, %Auth.Domain{log: "Signup failed: Invalid arguments", error: @failed_error}} =
             Google.check("", %{})

    payload = google_payload(%{"email_verified" => false})

    assert {:error, "Cannot sign in: federated identity is incomplete."} =
             Google.check("test.local", payload, :authed)

    # assert {:error, "Cannot sign in: federated identity is incomplete."} =
    #          Google.find_create_by_ident(%{}, "test.local", :authed)
    # end
    #
    # test "creates new user from verified Google identity" do
    #   payload = google_payload()
    payload = Map.put(payload, "email_verified", true)

    assert {:ok, %Auth.Domain{user: %User{id}, created: true}} =
             Google.find_create_by_ident(payload, "test.local", :authed)

    assert {:ok, %{user_id: ^id}} = User.ExtId.Lib.get("google", payload["sub"])
    assert {:ok, %Ident.Email{user_id: ^id}} = Ident.Email.one(address: payload["email"])
  end

  # test "recognizes existing Google identity" do
  #   user = insert(:ident_user, settings: %{})
  #   id = user.id
  #   payload = google_payload()
  #
  #   assert {:ok, _} = User.ExtId.Lib.put(user, "google", payload["sub"])
  #
  #   assert {:ok, %Auth.Domain{user: %User{id: ^id}, status: :authed}} =
  #            Google.find_create_by_ident(payload, "test.local", :authed)
  #
  #   assert {:ok, %User{settings: %{"authAllowed" => %{"google" => true}}}} =
  #            User.one(id: id)
  # end

  # test "links Google identity to user with existing email" do
  #   user = insert(:ident_user, settings: %{})
  #   id = user.id
  #   payload = google_payload()
  #
  #   assert {:ok, _} = User.Lib.add_email(user, payload["email"])
  #
  #   assert {:ok, %Auth.Domain{user: %User{id: ^id}}} =
  #            Google.find_create_by_ident(payload, "test.local", :authed)
  #
  #   assert {:ok, %{user_id: ^id}} = User.ExtId.Lib.get("google", payload["sub"])
  # end
  #
  # test "rejects user who has disabled Google signin" do
  #   user = insert(:ident_user, settings: %{"authAllowed" => %{"google" => false}})
  #   payload = google_payload()
  #
  #   assert {:ok, _} = User.ExtId.Lib.put(user, "google", payload["sub"])
  #
  #   assert {:error, %Auth.Domain{error: "The user has already signed in" <> _}} =
  #            Google.find_create_by_ident(payload, "test.local", :authed)
  # end
  #
  # test "rejects disabled user" do
  #   user = insert(:ident_user, type: :disabled, settings: %{})
  #   payload = google_payload()
  #
  #   assert {:ok, _} = User.ExtId.Lib.put(user, "google", payload["sub"])
  #
  #   assert {:error, %Auth.Domain{log: "Federated signin when user already exists"}} =
  #            Google.find_create_by_ident(payload, "test.local", :authed)
  # end
end
