defmodule Rivet.Ident.Test.EmailTest do
  use Rivet.Ident.Case, async: true

  # doctest Rivet.Ident.Email, import: true
  # doctest Rivet.Ident.Email.Lib, import: true

  test "model tests" do
    assert %Email{id} = insert(:ident_email)
    assert is_uuid(id)
    assert %Email{id: ^id} = Email.one!(id: id)
    params = params_with_assocs(:ident_email)
    assert {:ok, %Email{} = x} = Email.create(params)
    assert {:ok, _} = Email.delete(x)
  end

  test "sets verified" do
    email = insert(:ident_email)
    assert email.verified == false
    {:ok, updated} = Email.update(email, %{verified: true})
    assert updated.verified == true
  end

  test "sets primary" do
    email = insert(:ident_email)
    assert email.primary == false
    {:ok, updated} = Email.update(email, %{primary: true})
    assert updated.primary == true
  end

  test "bad records are properly denied" do
    attrs = params_with_assocs(:ident_email)
    assert {:error, chgs} = Email.create(Map.put(attrs, :address, ""))
    assert {"can't be blank", _} = Keyword.get(chgs.errors, :address)
    assert {:error, chgs} = Email.create(Map.put(attrs, :address, "hi"))
    assert {"needs to be a valid email address", _} = Keyword.get(chgs.errors, :address)
  end

  test "Lib" do
    u = insert(:ident_user)
    refute Email.Lib.has_verified?(u)
    insert(:ident_email, user: u, verified: true)
    assert Email.Lib.has_verified?(u)
  end
end
