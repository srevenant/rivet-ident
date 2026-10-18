defmodule Rivet.Ident.Test.Ident.User.CodeTest do
  use Rivet.Ident.Support.Case, async: true
  # use Rivet.Ident
  alias Rivet.Ident.User.Code

  @email_verify Code.type!(:email_verify)
  @delete_request Code.type!(:delete_request)

  test "model tests" do
    assert %Code{id} = insert(:ident_user_code)
    assert is_integer(id)
    assert %Code{id: ^id} = Code.one!(id: id)
    params = params_with_assocs(:ident_user_code)
    assert {:ok, %Code{} = x} = Code.create(params)
    assert {:ok, _} = Code.delete(x)
  end

  test "type!" do
    assert Code.type!(:password_reset) == :password_reset
    assert_raise RuntimeError, fn -> Code.type!(:bad) end
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

  describe "Lib" do
    setup do
      {:ok, %{user: insert(:ident_user)}}
    end

    test "generate and validate code", %{user: %{id: user_id}} do
      meta = %{"source" => "test"}

      assert {:ok, %{code, id: code_id, user_id: ^user_id, type: @email_verify, meta: ^meta}} =
               Code.Lib.generate_code(user_id, @email_verify, 10, meta)

      assert not_empty_str(code)
      assert {:ok, %{id: ^code_id}} = Code.Lib.get_valid(code)
    end

    test "expired codes are rejected and cleaned up", %{user: %{id}} do
      assert {:ok, %{code}} = Code.Lib.generate_code(id, @email_verify, -1)
      assert {:error, "Code Expired"} = Code.Lib.get_valid(code)

      Code.Lib.clear_expired_codes()

      assert {:error, :not_found} = Code.one(code: code)
    end

    test "reset codes only removes matching user and type", %{user: %{id}} do
      {:ok, old} = Code.Lib.generate_code(id, @delete_request, 10)
      {:ok, other} = Code.Lib.generate_code(id, @email_verify, 10)

      assert {:ok, fresh} = Code.Lib.reset_generate(id, @delete_request)
      assert fresh.code != old.code

      assert {:error, :not_found} = Code.one(code: old.code)
      assert {:ok, _} = Code.Lib.get_valid(fresh.code)
      assert {:ok, _} = Code.Lib.get_valid(other.code)
    end
  end
end
