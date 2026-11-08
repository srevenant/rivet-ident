defmodule Test.Rivet.Data.ToolsTest do
  use Rivet.Ident.Support.Case, async: true
  import Rivet.Data.Tools

  @valid_list [%{"id" => "a"}, %{"id" => "b"}, %{"id" => "c"}]
  @invalid_list [%{"id" => "a"}, %{"id" => "a"}, %{"id" => "b"}]

  test "pop_from_list" do
    assert {:ok, %{"id" => "b"}, [%{"id" => "a"}, %{"id" => "c"}]} ==
             pop_from_list(@valid_list, "b")

    assert {:ok, %{"id" => "a"}, [%{"id" => "b"}, %{"id" => "c"}]} ==
             pop_from_list(@valid_list, "a")

    assert {:error, "Item not found in list"} = pop_from_list(@valid_list, "z")
    assert {:error, "Too many items with same id in list"} = pop_from_list(@invalid_list, "a")
  end

  test "update_at" do
    assert {:ok, [%{"id" => "b"}, %{"id" => "c"}, %{"id" => "a", "name" => "z"}]} ==
             update_at(:tail, {"a", "name", "z"}, @valid_list)

    assert {:ok, [%{"id" => "a", "name" => "z"}, %{"id" => "b"}, %{"id" => "c"}]} ==
             update_at(:head, {"a", "name", "z"}, @valid_list)

    assert {:ok, [%{"id" => "a"}, %{"id" => "c", "name" => "z"}, %{"id" => "b"}]} ==
             update_at({:before, "b"}, {"c", "name", "z"}, @valid_list)

    assert {:ok, [%{"id" => "a"}, %{"id" => "c", "name" => "z"}, %{"id" => "b"}]} ==
             update_at({:after, "a"}, {"c", "name", "z"}, @valid_list)

    assert {:ok, [%{"id" => "a"}, %{"id" => "b"}, %{"id" => "c", "name" => "z"}]} ==
             update_at(:current, {"c", "name", "z"}, @valid_list)

    assert {:ok, [%{"id" => "a"}, %{"id" => "b", "name" => "z"}, %{"id" => "c"}]} ==
             update_at(:current, {"b", "name", "z"}, @valid_list)

    assert {:ok, [%{"id" => "a"}, %{"id" => "b"}, %{"id" => "c"}, %{"id" => "NO", "name" => "z"}]} =
             update_at(:current, {"NO", "name", "z"}, @valid_list)
  end

  test "insert_at" do
    assert {:ok, [%{"id" => "a"}, %{"id" => "b"}, %{"id" => "c"}, %{"id" => "z"}]} ==
             insert_at(:tail, %{"id" => "z"}, @valid_list)

    assert {:ok, [%{"id" => "z"}, %{"id" => "a"}, %{"id" => "b"}, %{"id" => "c"}]} ==
             insert_at(:head, %{"id" => "z"}, @valid_list)

    assert {:ok, [%{"id" => "z"}, %{"id" => "a"}, %{"id" => "b"}, %{"id" => "c"}]} ==
             insert_at({:before, "a"}, %{"id" => "z"}, @valid_list)

    assert {:ok, [%{"id" => "a"}, %{"id" => "b"}, %{"id" => "z"}, %{"id" => "c"}]} ==
             insert_at({:after, "b"}, %{"id" => "z"}, @valid_list)

    assert {:ok, [%{"id" => "a"}, %{"id" => "b"}, %{"id" => "c"}, %{"id" => "z"}]} ==
             insert_at({:after, "c"}, %{"id" => "z"}, @valid_list)

    assert {:ok, [%{"id" => "a"}, %{"id" => "b"}, %{"id" => "c"}, %{"id" => "z"}]} ==
             insert_at(:current, %{"id" => "z"}, @valid_list)

    assert {:ok, [%{"id" => "a"}, %{"id" => "b"}, %{"id" => "c"}, %{"id" => "z"}]} ==
             insert_at({:before, "v"}, %{"id" => "z"}, @valid_list)

    assert {:error, "Unsupported :at for insert"} = insert_at(:bad, :bad, :bad)
  end
end
