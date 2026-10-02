defmodule Rivet.Ident.Test.User.LibTest do
  use Rivet.Ident.Case, async: true
  use Rivet.Ident
  alias Rivet.Ident

    doctest User.Lib, import: true

      test "search" do
        name = "RICHTHOFEN"
        user = insert(:ident_user, name: name)
        insert(:ident_handle, user: user)
        insert(:ident_email, user: user)

        assert {:ok, [%Rivet.Ident.User{name: ^name}]} =
                 Rivet.Ident.User.Lib.search(%{matching: String.downcase(name)}, [])
      end

  test "signup" do
    assert {:error, %{error: "Sign up Failed"}} =
             User.Signup.signup(%Rivet.Auth.Domain{}, :authed)

    site = insert(:site)
    auth1 = build(:auth_domain_signin, site: site)
    assert {:ok, %Rivet.Auth.Domain{}} = User.Signup.signup(auth1, :authed)
    assert {:ok, %Rivet.Auth.Domain{}} = User.Signup.signup_only_identity(auth1)

    assert {:ok, %Email{}} =
             User.Signup.signup_create_with_email(
               auth1.site.domain,
               auth1.input.email.address
             )

    auth2 = build(:auth_domain_signin, site: site)

    assert {:ok, %Email{}} =
             User.Signup.rest_signup_user_email(
               auth2.site.domain,
               auth2.input.email.address
             )

    assert {:ok, %Rivet.Auth.Domain{}} =
             User.Signup.signup(
               build(:auth_domain_signin, handle: Ecto.UUID.generate() |> String.slice(0, 25)),
               :authed
             )
  end

  test "various" do
    uuid = Ecto.UUID.generate()
    assert [] = User.Lib.search_name!(uuid)
    assert [] = User.Lib.all_since(DateTime.utc_now())

    disabled = build(:user, type: :disabled)
    assert true == User.Lib.user_enabled?(build(:user))
    assert false == User.Lib.user_enabled?(disabled)
    errmsg = "sorry, account is disabled"

    assert {:error, %{error: ^errmsg}} =
             User.Lib.check_user_status({:ok, %Rivet.Auth.Domain{user: disabled}})

    assert {:error, %{error: ^errmsg}} = User.Lib.check_user_status(disabled)
    assert {:ok, _} = User.Lib.check_user_status(build(:user))
  end

  test "seen" do
    user = insert(:user)
    user_id = user.id
    assert %{id: ^user_id} = user = User.Lib.user_seen(user, build(:site))
    assert %{id: ^user_id} = User.Lib.user_seen(user, build(:site))
  end
end
