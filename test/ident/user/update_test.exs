defmodule Test.Rivet.Ident.UserUpdateTest do
  use Test.Support.Core.Case, async: true
  # use Core.ContextClient
  alias Db.Ident.User
  import Db.Ident.User.Update

  test "asdf" do
    u = insert(:user)
    site = insert(:site)
    meta = %{site: site}

    good = fn data ->
      assert {:ok, wut, _} = update(data, :admin, u, meta)
      wut
    end

    bad = fn data ->
      assert {:error, _} = update(data, :admin, u, meta)
    end

    ############################################################################
    assert %User{name: "red", type: :authed} = good.(%{user: %{name: "red"}, action: :upsert})
    # admin fully disables
    assert %User{type: :disabled} = good.(%{user: %{disable: true}, action: :upsert})
    # admin re-enables; put them to identified & they'll switch to authed on next sign in
    assert %User{type: :identity} = good.(%{user: %{disable: false}, action: :upsert})
    bad.(%{user: %{name: "red"}, action: :nope})

    ############################################################################
    assert %{phones: [%{id: id}]} = good.(%{phone: %{phone: "8015555555"}, action: :upsert})
    assert %{phones: []} = good.(%{phone: %{id: id}, action: :remove})
    bad.(%{phone: %{}})

    ############################################################################
    good.(%{handle: %{handle: "narf"}, action: :upsert})
    good.(%{handle: %{handle: "narf"}, action: :upsert})
    h = insert(:handle)
    {:error, "Sorry, that handle" <> _} = bad.(%{handle: %{handle: h.handle}, action: :upsert})
    bad.(%{handle: %{}})

    ############################################################################
    good_email = fn args ->
      u = good.(args)
      User.preload!(u, [:emails])
    end

    assert %User{emails: [%{id: id}]} =
             good_email.(%{email: %{email: "narf@example.com"}, action: :upsert})

    assert %User{emails: [%{id: ^id}]} =
             good_email.(%{email: %{id: id, verify: true}, action: :upsert})

    assert %User{emails: []} = good_email.(%{email: %{id: id}, action: :remove})
    bad.(%{email: %{}})

    ############################################################################
    good.(%{data: %{type: :license, key: "blue", value: "bar"}, action: :upsert})
    good.(%{data: %{type: :license, key: "blue", value: "bar"}, action: :remove})

    ############################################################################
    good.(%{role: %{name: "curator"}, action: :upsert})
    # test that adding same role a second time does not error
    u = good.(%{role: %{name: "curator"}, action: :upsert})
    {:ok, u} = Core.Auth.Cache.get_authz(u, force: true)
    assert MapSet.member?(u.authz, {@global_topic_edit_action, :global, nil})
    u = good.(%{role: %{name: "curator"}, action: :remove})
    {:ok, u} = Core.Auth.Cache.get_authz(u, force: true)
    refute MapSet.member?(u.authz, {@global_topic_edit_action, :global, nil})
  end
end
