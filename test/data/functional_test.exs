defmodule Test.Rivet.Data.FunctionalTest do
  use Rivet.Ident.Support.Case, async: true

  # this uses User.Data as an instance to test things
  alias Rivet.Ident.User.Data

  defp invalid(id, chg, d), do: Data.build_change(d, id, chg)
  defp invalid1(k, v, d \\ nil)
  defp invalid1(k, v, nil), do: invalid(nil, %{key: k, value: v}, build(:ident_user_data))
  defp invalid1(k, v, d), do: invalid(nil, %{key: k, value: v}, d)
  defp invalid2(id, at, k, v, d), do: invalid(id, %{id: id, key: k, value: v, at: at}, d)

  test "Data.build_change" do
    map = Map.new(0..30//1, &{"key#{&1}", &1})

    phat = Map.put(map, "blorp", "k")
    id = Ecto.UUID.generate()
    bigk = id <> id

    # should become 2304 in length
    bigd = Enum.reduce(0..4//1, bigk, fn _, acc -> acc <> acc end)
    pd = build(:ident_user_data)
    pd2 = build(:ident_user_data, type: :social, depth: :list, value: %{"list" => [%{"id" => id}]})

    # shallow
    assert {:error, "Invalid key for data"} = invalid1(:bad, "ok")
    assert {:error, "Invalid value type"} = invalid1("ok", :bad)
    assert {:error, "Invalid key for data"} = invalid1(bigk, "d")
    assert {:error, "Value is too long for data"} = invalid1("key", bigd)
    assert {:ok, _} = invalid1("key", "d", %{pd | value: map})
    assert {:error, "Too many values in data"} = invalid1("key", "d", %{pd | value: phat})

    assert {:error, "Invalid data inputs"} = invalid2(:bad, "@", "ok", "ok", pd2)

    # deep
    assert {:ok, %{"list" => [%{"id" => id, "name" => "v"}]}} ==
             invalid2(id, "@", "name", "v", pd2)

    assert {:ok, %{"list" => [%{"id" => newid, "name" => "v"}]}} =
             invalid2(nil, "@", "name", "v", %{pd2 | value: %{}})

    assert is_uuid(newid)

    assert {:error, "Invalid key for data"} = invalid2(id, "@", bigk, "d", pd2)
  end

  defp update_social2(p_id, key, value, args \\ %{at: "@"}),
    do: update_social(p_id, Map.merge(%{key: key, value: value}, args))

  defp update_social(p_id, args) do
    assert {:ok, %{value: %{"list" => list}}} =
             Data.data_update(Map.merge(%{user_id: p_id, type: :social}, args))

    list
  end

  test "Data.data_update & remove" do
    u = insert(:ident_user)

    assert {:error, %Ecto.Query.CastError{}} = Data.data_update(%{user_id: u.id, type: :bah})

    # create
    assert [%{"name" => "bork", "id" => id1}] = update_social2(u.id, "name", "bork")

    # update
    assert [%{"name" => "narf", "id" => id1}] ==
             update_social2(u.id, "name", "narf", %{id: id1, at: "@"})

    # need more for moving
    assert [%{"id" => ^id1}, %{"id" => id2}] = update_social2(u.id, "name", "second")

    assert [%{"id" => ^id1}, %{"id" => ^id2}, %{"id" => id3}] =
             update_social2(u.id, "name", "third")

    assert [%Data{value: %{"list" => [%{"id" => ^id1}, %{"id" => ^id2}, %{"id" => ^id3}]}}] =
             Data.all!(user_id: u.id)

    assert [%{"id" => ^id2}, %{"id" => ^id1}, %{"id" => ^id3}] =
             update_social(u.id, %{id: id2, at: "<#{id1}"})

    assert [%{"id" => ^id1}, %{"id" => ^id3}, %{"id" => ^id2}] =
             update_social(u.id, %{id: id2, at: "-1"})

    assert [%{"id" => ^id1}, %{"id" => ^id3}, %{"id" => ^id2}] =
             update_social(u.id, %{id: id1, at: "+"})

    assert [%{"id" => ^id3}, %{"id" => ^id1}, %{"id" => ^id2}] =
             update_social(u.id, %{id: id1, at: "-"})

    assert [%{"id" => ^id3}, %{"id" => ^id1}, %{"id" => ^id2}] =
             update_social(u.id, %{id: id2, at: "-"})

    # remove
    assert {:ok, %Data{value: %{"list" => [_, _]}}} =
             Data.data_remove(%{user_id: u.id, type: :social, id: id1})

    # non-deep
    assert {:ok, _} =
             Data.data_update(%{
               user_id: u.id,
               type: :save,
               key: "save",
               value: "bork bork"
             })

    assert [%Data{}, %Data{}] = Data.all_of_types(u, [:save, :social])
    assert {:ok, %Data{}} = Data.get_by_type(u, :save)

    # remove
    assert {:ok, %Data{}} = Data.data_remove(%{user_id: u.id, type: :save, key: "save"})

    assert [%Data{value: %{}}] = Data.all!(user_id: u.id, type: :save)

    assert :error = Data.get_by_type(u, :address)
  end

  test "upsert_for_origin" do
    u = insert(:ident_user)

    # create
    assert {:ok, _} = Data.upsert_for_origin(u.id, :save, :narf, 100)
    # and update
    assert {:ok, _} = Data.upsert_for_origin(u.id, :save, :narf, 200)
  end
end
