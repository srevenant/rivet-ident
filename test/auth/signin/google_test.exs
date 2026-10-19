defmodule Rivet.Ident.Test.Auth.GoogleTest do
  use Rivet.Ident.Support.Case
  use Rivet.Ident
  alias Rivet.Auth
  alias Rivet.Auth.Signin.Google

  @client_id Application.compile_env!(:rivet_ident, :federated)[:google_client_id]

  defp google_payload(overrides \\ %{}) do
    now = System.system_time(:second)

    Map.merge(
      %{
        "email_verified" => true,
        "sub" => Ecto.UUID.generate(),
        "email" => "google-#{Ecto.UUID.generate()}@example.com",
        "name" => "Google Test",
        "locale" => "en",
        "iss" => "https://accounts.google.com",
        "aud" => @client_id,
        "azp" => @client_id,
        "iat" => now,
        "exp" => now + 3600,
        "jti" => Ecto.UUID.generate(),
        "token" => "test-token"
      },
      overrides
    )
  end

  defp test_token(claims),
    do: "test:" <> (claims |> Jason.encode!() |> Base.url_encode64(padding: false))

  defp check_google(payload, type \\ :authed),
    do: Google.check("test.local", %{"data" => %{"auth" => test_token(payload)}}, type)

  @failed_error "Unable to sign in."
  defp assert_authfail(log, func), do: assert_authfail(log, @failed_error, func)

  defp assert_authfail(log, error, func) do
    log = "Google signin failed: #{log}"
    assert {:error, %Auth.Domain{log: ^log, error: ^error}} = func.()
  end

  test "errors" do
    assert_authfail("Invalid arguments", fn -> Google.check("", %{}) end)

    assert_authfail("User identified but unable to load", fn ->
      Google.check_user_allowed({:error, nil}, nil)
    end)

    assert_authfail("Cannot sign in: federated identity is incomplete.", fn ->
      check_google(google_payload(%{"email_verified" => false}))
    end)

    assert :nope = Google.add_ident(:nope, nil)
  end

  test "invalid claims" do
    now = System.system_time(:second)

    [
      %{"exp" => now - 60},
      %{"iss" => "https://not-google.com"},
      %{"aud" => "wrong-client-id"},
      %{"exp" => nil}
    ]
    |> Enum.each(fn claim ->
      assert_authfail("Invalid Google test token", fn -> check_google(google_payload(claim)) end)
    end)
  end

  test "creates new user from verified Google identity" do
    payload = google_payload()

    assert {:ok, %Auth.Domain{user: %User{id: id}, created: true}} = check_google(payload)
    assert {:ok, %{user_id: ^id}} = User.ExtId.Lib.get("google", payload["sub"])
    assert {:ok, %Ident.Email{user_id: ^id}} = Ident.Email.one(address: payload["email"])
  end

  test "recognizes existing Google identity" do
    user = insert(:ident_user, settings: %{"authAllowed" => %{"narf" => true}})
    id = user.id
    payload = google_payload()

    assert {:ok, _} = User.ExtId.Lib.put(user, "google", payload["sub"])

    assert {:ok, %Auth.Domain{user: %User{id: ^id}, status: :authed}} =
             check_google(payload)

    assert {:ok, %User{settings: %{"authAllowed" => %{"google" => true}}}} =
             User.one(id: id)
  end

  test "links Google identity to user with existing email" do
    user = insert(:ident_user, settings: %{})
    id = user.id
    payload = google_payload()

    assert {:ok, _} = User.Lib.add_email(user, payload["email"])

    assert {:ok, %Auth.Domain{user: %User{id: ^id}}} = check_google(payload)
    assert {:ok, %{user_id: ^id}} = User.ExtId.Lib.get("google", payload["sub"])
  end

  test "rejects user who has disabled Google signin" do
    user = insert(:ident_user, settings: %{"authAllowed" => %{"google" => false}})
    payload = google_payload()

    assert {:ok, _} = User.ExtId.Lib.put(user, "google", payload["sub"])

    assert_authfail(
      "Federated signin disabled for user",
      "You have not authorized google logins. Perhaps try to reset your password?",
      fn -> check_google(payload) end
    )
  end

  test "rejects disabled user" do
    user = insert(:ident_user, type: :disabled, settings: %{})
    payload = google_payload()

    assert {:ok, _} = User.ExtId.Lib.put(user, "google", payload["sub"])

    assert_authfail(
      "Attempted login on disabled account",
      "Sorry, account is disabled",
      fn -> check_google(payload) end
    )
  end
end
