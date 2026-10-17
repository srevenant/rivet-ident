defmodule Rivet.Ident.Test.Ident.User.SignupTest do
  use Rivet.Ident.Test.Case, async: true
  use Rivet.Ident
  alias Rivet.Auth
  alias User.Signup

  test "signup" do
    assert {:error, %{error: "No password given"}} =
             Signup.signup(%Auth.Domain{input: %{secret: ""}}, :authed)

    auth1 = build(:auth_domain_signin)

    assert {:ok, %Auth.Domain{}} = Signup.signup(auth1, :authed)

    auth2 = build(:auth_domain_signin)

    assert :ok = Signup.good_password(%Auth.Domain{})

    assert "narf" == Signup.get_default_name(%Auth.Domain{input: %{name: "narf"}})

    assert "narf" ==
             Signup.get_default_name(%Auth.Domain{input: %{email: %{address: "narf@narf"}}})

    assert "no name" == Signup.get_default_name(%Auth.Domain{})

    assert {:ok, %Auth.Domain{user: %User{}}} = Signup.signup(auth2, :identity)
  end

  # test "signup_create_with_email" do
  #   site = build(:auth_domain_signin).site |>dbg
  #   address = "signup-#{Ecto.UUID.generate()}@example.com"
  #
  #   assert {:ok, %Auth.Domain{user: %User{id: user_id}, status: :identity, created: true}} =
  #            Signup.signup_create_with_email(address, site)
  #
  #   assert {:ok, %Email{user_id: ^user_id, verified: false}} = Email.one(address: address)
  # end

  test "authed signup requires a factor" do
    auth = build(:auth_domain_signin)
    input = Map.drop(auth.input, [:secret, :fedid])

    assert {:error, %Auth.Domain{error: "Unable to add user factor", user: %{id: id}}} =
             Signup.signup(%Auth.Domain{auth | input: input}, :authed, no_send: true)

    # Failed signup must roll back the created user
    assert {:error, :not_found} = User.one(id: id)
  end

  test "signup requires an email" do
    auth = build(:auth_domain_signin)
    input = Map.delete(auth.input, :email)

    assert {:error, %Auth.Domain{error: "Email address required", user: %{id: id}}} =
             Signup.signup(%Auth.Domain{auth | input: input}, :identity, no_send: true)

    assert {:error, :not_found} = User.one(id: id)
  end

  test "federated signup creates a factor" do
    auth = build(:auth_domain_signin)
    fedid = build(:ident_factor_fedid)
    input = auth.input |> Map.delete(:secret) |> Map.put(:fedid, fedid)

    assert {:ok, %Auth.Domain{user: %User{id: id}, status: :authed}} =
             Signup.signup(%Auth.Domain{auth | input: input}, :authed, no_send: true)

    assert {:ok, %Ident.Factor{user_id: ^id}} = Ident.Factor.one(user_id: id)
  end
end
