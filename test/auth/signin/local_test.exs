defmodule Rivet.Ident.Test.Auth.Signin.LocalTest do
  @moduledoc """

  NOTE NOTE NOTE NOTE

  This is a slow test because of all the password hash checking.

  """
  use Rivet.Ident.Support.Case, async: true
  use Rivet.Ident
  alias Rivet.Auth
  alias Rivet.Auth.Identify
  alias Rivet.Auth.Signin.Local

  @password "VFR$#EDCvfr43edc"
  @common_error "Signup failed. Perhaps try password recovery?"
  # @hashed Factor.Password.hash(@password)

  test "Signin Local" do
    user_handle = "narf"
    user_email = "narf@narf.com"

    good_user = %{
      "handle" => user_handle,
      "password" => @password,
      "email" => user_email
    }

    assert {:ok, %Auth.Domain{status: :authed, user: user}} =
             Local.signup("example.com", good_user)

    user_id = user.id
    error = "Signup failed: A signin already exists for `#{user_email}`"

    assert {:error, %Auth.Domain{log: ^error, error: @common_error}} =
             Local.signup("example.com", good_user)

    # Check
    assert {:ok, %Auth.Domain{status: :authed}} =
             Local.check(%Auth.Domain{status: :narf}, %{
               "handle" => user_handle,
               "password" => @password
             })

    assert {:error,
            %Auth.Domain{
              error: "Unable to sign in. Did you want to sign up instead?",
              log: "Cannot find person ~doctor"
            }} = Local.check(%Auth.Domain{}, %{"handle" => "doctor", "password" => "who"})

    assert {:error, _} = Local.check("hostname", %{"handle" => "doctor", "password" => "who"})

    # Load user
    assert {:error, %{log: "Cannot find email red@narf"}} =
             Local.load_user(%Auth.Domain{}, "red@narf")

    assert {:ok, %{user: %Ident.User{id: ^user_id}}} = Local.load_user(%Auth.Domain{}, user_email)

    # double-tap this test for Identify too
    assert {:error, %Auth.Domain{error: "Sorry, that email address" <> _}} =
             Identify.identify("example.com", %{email: user_email})

    assert {:ok, %Auth.Domain{}} = Identify.identify("example.com", %{email: "new@blah.com"})
  end

  test "bad args" do
    assert {:error,
            %Auth.Domain{
              error: @common_error,
              log: "Signup failed: Invalid arguments"
            }} = Local.signup("example.com", "narf")

    params = %{"handle" => "ahandle", "password" => @password, "email" => "email@address.com"}

    test_bad = fn a, b ->
      assert {:error, %{log, error, status: :unknown}} =
               Local.signup("example.com", Map.put(params, a, b))

      assert error == log
      assert "Signup failed; Missing #{a}" == log
    end

    test_bad.("handle", nil)
    test_bad.("password", "")
    test_bad.("email", nil)
  end
end

# assert {:error, "narf"} = test_bad.("handle", "bad@handle")
