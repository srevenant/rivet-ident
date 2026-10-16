defmodule Rivet.Ident.Test.Ident.User.SignupTest do
  use Rivet.Ident.Test.Case, async: true
  use Rivet.Ident
  alias Rivet.Auth

  test "signup" do
    assert {:error, %{error: "No password given"}} = User.Signup.signup(%Auth.Domain{}, :authed)

    auth1 = build(:auth_domain_signin)

    assert {:ok, %Auth.Domain{}} = User.Signup.signup(auth1, :authed)

    auth2 = build(:auth_domain_signin)

    assert {:ok, %Auth.Domain{}} = User.Signup.signup(auth2, :identity, %{no_send: false})

    # assert {:ok, %Email{}} =
    #          User.Signup.signup_create_with_email(
    #            auth1.site.domain,
    #            auth1.input.email.address
    # )

    # auth2 = build(:auth_domain_signin)
    # assert {:ok, %Email{}} =
    #          User.Signup.rest_signup_user_email(
    #            auth2.site.domain,
    #            auth2.input.email.address
    #          )
  end
end
