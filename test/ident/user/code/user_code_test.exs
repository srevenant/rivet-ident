defmodule Rivet.Ident.Test.UserCodeTest do
  use Rivet.Ident.Case, async: true
  alias Rivet.Ident.UserCode

  test "model tests" do
    assert %UserCode{id} = insert(:ident_user_code)
    assert is_uuid(id)
    assert %UserCode{id: ^id} = UserCode.one!(id: id)
    params = params_with_assocs(:ident_user_code)
    assert {:ok, %UserCode{} = x} = UserCode.create(params)
    assert {:ok, _} = UserCode.delete(x)
  end

    # test "Lib.email_verify_code" do
    #   assert {:error, "Invalid EmailVerify Code" <> _} = UserCode.Lib.email_verify_code("nope")
    #
    #   %{user} = bad = insert(:verify_email_code)
    #   %{emails: [e]} = Core.Db.Ident.User.preload!(user, [:emails])
    #
    #   assert {:ok, _} = Core.Db.Ident.Email.delete(e)
    #
    #   assert {:error, "Email Verification Failed: cannot lookup by email_id"} =
    #            UserCode.Lib.email_verify_code(bad.code)
    #
    #   code = insert(:verify_email_code)
    #   assert {:redirect, _} = UserCode.Lib.email_verify_code(code.code)
    # end
end
