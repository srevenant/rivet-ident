defmodule Rivet.Ident.Test.Ident.User.CodeTest do
  use Rivet.Ident.Test.Case, async: true
  use Rivet.Ident
  alias Rivet.Ident.User.Code

  test "model tests" do
    assert %Code{id} = insert(:ident_user_code)
    assert is_integer(id)
    assert %Code{id: ^id} = Code.one!(id: id)
    params = params_with_assocs(:ident_user_code)
    assert {:ok, %Code{} = x} = Code.create(params)
    assert {:ok, _} = Code.delete(x)
  end

  ### requires :mailer; move to a supplementary Mailer lib
  # test "Lib.email_verify_code" do
  #   assert {:error, "Invalid EmailVerify Code" <> _} = Code.Lib.email_verify_code("nope")
  #
  #   %{user} = bad = insert(:verify_email_code)
  #   %{emails: [e]} = Rivet.Ident.User.preload!(user, [:emails])
  #
  #   assert {:ok, _} = Rivet.Ident.Email.delete(e)
  #
  #   assert {:error, "Email Verification Failed: cannot lookup by email_id"} =
  #            Code.Lib.email_verify_code(bad.code)
  #
  #   code = insert(:verify_email_code)
  #   assert {:redirect, _} = Code.Lib.email_verify_code(code.code)
  # end
end
