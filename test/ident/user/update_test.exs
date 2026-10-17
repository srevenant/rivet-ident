defmodule Rivet.Ident.Test.Ident.User.UpdateTest do
  use Rivet.Ident.Test.Case, async: true
  use Rivet.Ident
  alias User.Update

  defp test_update(action, type, chg, user, opts \\ [auth: :user]),
    do: Update.update(Map.put(%{action}, type, chg), user, opts)

  defp test_invalid_change(target, wat \\ nil) do
    func = String.to_atom("update_#{target}")
    str = "Invalid #{wat || target} change configuration"
    assert {:error, ^str} = apply(Update, func, [nil, nil, nil, nil])
  end

  describe "User.Update.update" do
    setup do
      user = insert(:ident_user, name: "Doctor")
      upsert2 = fn type, chg -> test_update(:upsert, type, chg, user) end
      upsert3 = fn type, chg, opt -> test_update(:upsert, type, chg, user, opt) end
      remove2 = fn type, chg -> test_update(:remove, type, chg, user) end
      remove3 = fn type, chg, opt -> test_update(:remove, type, chg, user, opt) end

      {:ok, %{user, upsert2, upsert3, remove2, remove3}}
    end

    test "default opt & bad args", %{user} do
      assert {:error, "No updates found"} = Update.update(%{}, user)

      test_invalid_change(:user)
      test_invalid_change(:phone)
      test_invalid_change(:handle)
      test_invalid_change(:email)
      test_invalid_change(:role)
      test_invalid_change(:data)
    end

    test ":user", %{upsert2, upsert3, user: %{type: :authed}} do
      assert {:ok, %User{name: "Who"}} = upsert2.(:user, %{name: "Who"})
      assert {:error, "You must provide a name"} = upsert2.(:user, %{name: ""})
      # doesn't stick because :user
      assert {:error, "Invalid user/disable change configuration"} =
               upsert3.(:user, %{disable: true}, auth: :user)

      # does stick because :admin
      assert {:ok, %User{type: :disabled}} = upsert3.(:user, %{disable: true}, auth: :admin)
      assert {:ok, %User{type: :identity}} = upsert3.(:user, %{disable: false}, auth: :admin)

      assert {:error, "Update of type is disallowed"} =
               upsert3.(:user, %{type: :narf}, auth: :admin)
    end

    test ":phone", %{remove2, upsert2, user} do
      assert %User{phones: []} = User.one!([id: user.id], [:phones])
      assert {:ok, %User{phones: [%{id}]}} = upsert2.(:phone, %{number: "555-555-555"})
      assert %User{phones: [%{id: ^id}]} = User.one!([id: user.id], [:phones])
      assert {:ok, %User{phones: []}} = remove2.(:phone, %{id})
      assert {:error, :not_found} = remove2.(:phone, %{id: Ecto.UUID.generate()})
    end

    test ":handle", %{upsert2, user} do
      # default factor is an invalid user and has no handle
      assert %User{handle: nil} = User.one!([id: user.id], [:handle])
      # add
      assert {:ok, %User{handle: %{handle: "narf"}}} = upsert2.(:handle, %{handle: "narf"})
      # no change
      assert {:ok, %User{handle: %{handle: "narf"}}} = upsert2.(:handle, %{handle: "narf"})
      # change
      assert {:ok, %User{handle: %{handle: "bork"}}} = upsert2.(:handle, %{handle: "bork"})

      %{handle} = insert(:ident_handle)
      assert {:error, "Sorry, that handle isn't available"} = upsert2.(:handle, %{handle})
    end

    test ":email", %{upsert2, remove2, user} do
      assert %User{emails: []} = User.one!([id: user.id], [:emails])

      assert {:ok, %User{emails: [%{id, address: "boo@boo.com"}]}} =
               upsert2.(:email, %{address: "boo@boo.com"})

      assert {:ok, %User{emails: [%{id: ^id}]}} = upsert2.(:email, %{address: "boo@boo.com"})

      # re-send verification
      assert {:ok, %User{emails: [%{id: ^id}]}} = upsert2.(:email, %{id, verify: true})

      # delete
      assert {:ok, %User{emails: []}} = remove2.(:email, %{id})
    end

    test ":data", %{upsert2, remove2, user} do
      assert %User{data: []} = User.one!([id: user.id], [:data])

      assert {:ok, %User{data: [%{id, type: :address}]}} =
               upsert2.(:data, %{type: :address, value: %{}})

      assert {:ok, %User{data: [%{id: ^id, value: %{"narf" => 1}}]}} =
               upsert2.(:data, %{id, value: %{narf: 1}})

      assert {:ok, %User{data: []}} = remove2.(:data, %{id})
    end

    test ":role", %{upsert2, upsert3, remove3, user} do
      %{id: role_id} = insert(:ident_role)

      assert %User{accesses: []} = User.one!([id: user.id], [:accesses])
      assert {:error, "Invalid role/auth" <> _} = upsert2.(:role, %{id: role_id})
      assert {:error, "Invalid role/missing" <> _} = upsert3.(:role, %{id: 1}, auth: :admin)
      assert {:error, "Invalid role/args" <> _} = remove3.(:role, %{id: role_id}, auth: :admin)

      assert {:ok, %User{accesses: [%{role_id: ^role_id}]}} =
               upsert3.(:role, %{id: role_id}, auth: :admin)

      assert {:ok, %User{accesses: [%{role_id: ^role_id}]}} =
               upsert3.(:role, %{id: role_id}, auth: :admin)

      assert {:ok, %User{accesses: []}} = remove3.(:role, %{id: role_id}, auth: :admin)
    end
  end
end
