defmodule Rivet.Ident.Test.Ident.User.Code.ModelTest do
  use Rivet.Ident.Test.Case, async: true
  alias Rivet.Ident.User.Code

  test "model tests" do
    assert %User.Code{id} = insert(:ident_user_code)
    assert is_uuid(id)
    assert %User.Code{id: ^id} = User.Code.one!(id: id)
    params = params_with_assocs(:ident_user_code)
    assert {:ok, %User.Code{} = x} = User.Code.create(params)
    assert {:ok, _} = User.Code.delete(x)
  end

  # test "Lib.email_verify_code" do
  #   assert {:error, "Invalid EmailVerify Code" <> _} = User.Code.Lib.email_verify_code("nope")
  #
  #   %{user} = bad = insert(:verify_email_code)
  #   %{emails: [e]} = Rivet.Ident.User.preload!(user, [:emails])
  #
  #   assert {:ok, _} = Rivet.Ident.Email.delete(e)
  #
  #   assert {:error, "Email Verification Failed: cannot lookup by email_id"} =
  #            User.Code.Lib.email_verify_code(bad.code)
  #
  #   code = insert(:verify_email_code)
  #   assert {:redirect, _} = User.Code.Lib.email_verify_code(code.code)
  # end
end
