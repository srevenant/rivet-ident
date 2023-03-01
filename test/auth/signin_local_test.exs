defmodule Rivet.Auth.Test.Signin.LocalTest do
  @moduledoc """
  This is a slow test because of all the password hash checking.
  """
  use Rivet.Data.Ident.Case, async: true
  alias Rivet.Auth.Domain
  alias Rivet.Auth.Signin.Local
  alias Rivet.Data.Ident
  import ExUnit.CaptureLog
  import Rivet.Data.Ident.Test.Factory

  test "Signin Local" do
    assert capture_log(fn ->
             # Signup
             assert {:error,
                     %Domain{
                       log: "Auth signup failed, arguments don't match",
                       error: "Signup Failed"
                     }} = Local.signup("example.com", "narf")

             user_pass = "jelly"
             user_handle = "narf"
             user_email = "narf@narf.com"

             good_user = %{
               "handle" => user_handle,
               "password" => user_pass,
               "email" => user_email
             }

             assert {:ok, %Domain{status: :authed, user: user}} =
                      Local.signup("example.com", good_user)

             user_id = user.id
             error = "A signin already exists for `#{user_email}`"

             assert {:error, %Domain{error: ^error}} = Local.signup("example.com", good_user)

             # Check
             assert {:ok, %Domain{status: :authed}} =
                      Local.check(%Domain{status: :narf}, %{
                        "handle" => user_handle,
                        "password" => user_pass
                      })

             assert {:error,
                     %Domain{
                       error: "Unable to sign in. Did you want to sign up instead?",
                       log: "Cannot find person ~doctor"
                     }} = Local.check(%Domain{}, %{"handle" => "doctor", "password" => "who"})

             assert {:error, _} =
                      Local.check("hostname", %{"handle" => "doctor", "password" => "who"})

             # Load user
             assert {:error, %{log: "Cannot find email red@narf"}} =
                      Local.load_user({:ok, %Domain{}}, "red@narf")

             assert {:error, %{log: "Cannot find person ~red"}} =
                      Local.load_user({:ok, %Domain{}}, "red")

             assert {:ok, %{user: %Ident.User{id: ^user_id}}} =
                      Local.load_user({:ok, %Domain{}}, user_email)

             # Load password factor
             newu = insert(:ident_user)

             assert {:error, %Domain{log: "No auth factor for user"}} =
                      Local.load_password_factor({:ok, %Domain{user: newu}})

             #
             # # Check password
             # password = "Bad Wolf"
             # hashed = Utils.Hash.password(password)
             # assert true == Local.check_password(hashed, password)
             # assert false == Local.check_password(hashed, "Time Lord")
             assert true == Local.check_password(user, user_pass)
             assert false == Local.check_password(newu, "not")
             assert false == Local.check_password(:bork, nil)

             # valid_user_factor

             assert {:ok, [factor]} = Ident.Factor.all(user_id: user.id)

             assert {:error, %Domain{status: :unknown, log: "Invalid Password"}} =
                      Local.valid_user_factor(
                        {:ok, %Domain{user: user, factor: factor}},
                        "narf"
                      )

             assert {:error, %Domain{status: :unknown, log: "No password factor exists for user"}} =
                      Local.valid_user_factor({:ok, %Domain{user: user}}, user_pass)

             assert {:ok, %Domain{status: :authed}} =
                      Local.valid_user_factor(
                        {:ok, %Domain{user: user, factor: factor}},
                        user_pass
                      )

             # assert :narf = Local.valid_user_factor({:ok, %Domain{}}, "narf")
           end) =~ "Signin Success"
  end
end