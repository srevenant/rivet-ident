defmodule Rivet.Ident.Test.Ident.Factor.LibTest do
  # false because we are modifying application configs
  use Rivet.Ident.Support.Case, async: false
  use Rivet.Ident

  import Rivet.Ident.Factor.Lib
  # alias Rivet.Ident.Factor.Lib

  test "strong_password" do
    assert :ok = strong_password("<KO)(IJM,ko09ijm")
    assert {:error, "Password is not long enough (greater than 8)"} = strong_password("boo")

    assert {:error, "Password needs both upper and lower case characters"} =
             strong_password("<ko)(ijm,ko09ijm")

    assert {:error, "Password needs special characters (not alphanumeric)"} =
             strong_password("KOIJMko09ijm")

    assert {:error, "Password needs numbers"} = strong_password("<KO)(IJM,koijm")
    assert {:error, "Password needs letters"} = strong_password("<)(,)(*&^%$#@><")
  end

  test "passwords expired after new is set" do
    user = insert(:ident_user)

    assert {:ok, %{expires_at, id: old_id} = old} = set_password(user, "Password1!")
    # fake the old expiration
    adjusted = expires_at + 3600
    assert {:ok, %{expires_at: ^adjusted}} = Ident.Factor.update(old, %{expires_at: adjusted})

    # add a new one
    assert {:ok, _} = set_password(user, "Password2!")

    # test if the old was expired...
    assert {:ok, %Ident.Factor{} = old} = Ident.Factor.one(id: old_id)
    assert old.expires_at != expires_at
  end

  test "password history is automatically pruned" do
    user = insert(:ident_user)

    hist = Application.get_env(:rivet_ident, :password_history)
    create = hist + 2

    factors =
      Enum.map(1..create, fn n ->
        assert {:ok, factor} = set_password(user, "Password#{n}!")
        factor
      end)

    passwords = User.preload!(user, [:factors]).factors

    assert length(passwords) == hist

    now = System.system_time(:second)
    Enum.count(passwords, &(&1.expires_at <= now))
    assert Enum.count(passwords, &(&1.expires_at <= now)) == hist - 1
    assert Enum.count(passwords, &(&1.expires_at > now)) == 1

    assert Enum.any?(passwords, &(&1.id == List.last(factors).id))
  end

  test "expired factors are handled properly across types" do
    user = insert(:ident_user)
    now = System.system_time(:second)

    assert {:ok, old} = set_password(user, "Password1!")

    assert {:ok, current} = set_password(user, "Password2!")

    # mixing and matching passwords and federated blah
    expired = insert(:ident_factor, type: :federated, user: user, expires_at: now - 3600)
    active = insert(:ident_factor, type: :federated, user: user, expires_at: now + 3600)

    # test more
    ids = fn factors -> MapSet.new(Enum.map(factors, & &1.id)) end

    assert ids.(all_not_expired!(user)) == MapSet.new([active.id, current.id])

    assert ids.(all_not_expired!(user, :federated)) == MapSet.new([active.id])
    assert ids.(all_not_expired!(user, "federated")) == MapSet.new([active.id])
    assert ids.(all_not_expired!(user, :password)) == MapSet.new([current.id])

    drop_expired()

    assert {:error, :not_found} = Ident.Factor.one(id: expired.id)
    assert {:ok, _} = Ident.Factor.one(id: active.id)
    assert {:ok, _} = Ident.Factor.one(id: old.id)
    assert {:ok, _} = Ident.Factor.one(id: current.id)
  end
end
