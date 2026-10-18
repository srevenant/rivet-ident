defmodule Rivet.Ident.Test.Auth.AccessTest do
  use Rivet.Ident.Support.Case, async: true
  alias Rivet.Auth
  alias Auth.Access

  import Rivet.Ident.Support.Auth, only: [user_with_access_token: 0]

  test "Access" do
    assert {:missing, %Auth.Domain{log: "Missing authorization header value"}} =
             Access.check([""], %Auth.Domain{})

    assert {:missing, %Auth.Domain{log: "Missing authorization header value"}} =
             Access.check([], %Auth.Domain{})

    assert {:error, %Auth.Domain{log: "Cannot find matching key for authorization type :acc"}} =
             Access.check(["bearer token"], %Auth.Domain{})

    assert {:error,
            %Auth.Domain{log: "Authorization header exists but is not formatted properly"}} =
             Access.check(["narf"], %Auth.Domain{})

    assert {:error, %Auth.Domain{log: "Invalid authorization type: narf"}} =
             Access.check(["narf narf"], %Auth.Domain{})

    assert {:ok,
            %{
              hostname,
              token,
              user: %User{id: user_id} = user,
              args: %{exp, sub: "cas1:" <> _, aud: "caa1:acc:" <> _}
            }} = user_with_access_token()

    assert exp > 0

    auth = %Auth.Domain{hostname}

    assert {:ok, %Auth.Domain{status: :authed, user: %User{id: ^user_id}, token: %{ref: ^token}}} =
             Auth.Access.check(["Bearer " <> token], auth)

    # # invalid user
    assert {:ok, %{type: :disabled}} = User.update(user, %{type: :disabled})

    Ident.Factor.Cache.invalidate_all_for(user.id)

    assert {:error, %Auth.Domain{error: "Sorry, account is disabled"}} =
             Auth.Access.check(["bearer " <> token], auth)
  end
end
