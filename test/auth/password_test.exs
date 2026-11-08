defmodule Rivet.Ident.Test.Auth.PasswordTest do
  @moduledoc """

  NOTE NOTE NOTE NOTE

  This is a slow test because of all the password hash checking.

  """
  use Rivet.Ident.Support.Case, async: true
  alias Rivet.Auth
  import Rivet.Auth.Password
  use Rivet.Ident
  alias Rivet.Ident.Factor

  @password "VFR$#EDCvfr43edc"
  @hashed Factor.Password.hash(@password)

  test "strong_password" do
    min_len = Application.fetch_env!(:rivet_ident, :password_min_length)
    assert :ok = strong_password("<KO)(IJM,ko09ijm")
    err = "Password is not long enough (greater than #{min_len})"
    assert {:error, ^err} = strong_password("boo")

    assert {:error, "Password needs both upper and lower case characters"} =
             strong_password("<ko)(ijm,ko09ijm")

    assert {:error, "Password needs special characters (not alphanumeric)"} =
             strong_password("KOIJMko09ijm")

    assert {:error, "Password needs numbers"} = strong_password("<KO)(IJM,koijm")
    assert {:error, "Password needs letters"} = strong_password("<)(,)(*&^%$#@><")
  end

  test "load_password_factor" do
    user = insert(:ident_user)

    assert {:error, %Auth.Domain{log: "No user to lookup factor"}} =
             load_password_factor(%Auth.Domain{})

    assert {:error, %Auth.Domain{log: "No auth factor for user"}} =
             load_password_factor(%Auth.Domain{user})
  end

  test "matching_password_hash?" do
    assert matching_password_hash?(@hashed, @password)
    refute matching_password_hash?(@hashed, "Time Lord")
    refute matching_password_hash?(:narf, "Time Lord")
  end

  test "change_password*" do
    %{user} = code = insert(:ident_user_code)

    refute matching_password?(user, "Nope")

    assert {:error, "Password change failure: current password mis-match"} =
             change_password_matching(user, "narf", @password)

    assert {:ok, %User.Code{}} = change_password_code(code, @password)

    assert {:error, "Password reset code has already been used"} =
             change_password_code(code, @password)

    assert {:error, "Invalid password reset code"} =
             change_password_code(%{code | id: 0}, @password)

    assert {:error, "New password is the same as old"} =
             change_password_matching(user, @password, @password)

    assert {:error, :args} = change_password_code(nil, nil)
    assert {:error, :args} = change_password_matching(nil, nil, nil)

    assert {:ok, %Factor{}} = change_password_matching(user, @password, @password <> "x")

    expired = insert(:ident_user_code, expires: DateTime.add(DateTime.utc_now(), -86400))
    assert {:error, "Password reset code is expired"} = change_password_code(expired, @password)
  end

  test "valid_password_factor" do
    user = insert(:ident_user)

    assert {:error,
            %Auth.Domain{
              status: :unknown,
              error: "Invalid Password",
              log: "No password factor"
            }} =
             valid_password_factor(%Auth.Domain{user}, "narf")

    factor = insert(:ident_factor, user: user, type: :password, secret: @password, hash: @hashed)

    factor_id = factor.id
    user_id = user.id

    assert {:error,
            %Auth.Domain{
              status: :unknown,
              error: "Invalid Password",
              log: "Password does not match"
            }} =
             valid_password_factor(%Auth.Domain{user, factor}, "narf")

    assert {:ok,
            %Auth.Domain{
              user: %User{id: ^user_id},
              factor: %Factor{id: ^factor_id},
              status: :authed
            }} =
             valid_password_factor(%Auth.Domain{user}, @password)
  end
end
