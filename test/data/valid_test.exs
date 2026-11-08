defmodule Test.Rivet.Data.ValidTest do
  use Rivet.Ident.Support.Case, async: true
  import Rivet.Data.Valid

  test "valid_at" do
    id1 = Ecto.UUID.generate()
    id2 = Ecto.UUID.generate()

    assert {:ok, {:after, id2}} == valid_at(id1, ">" <> id2)
    assert {:ok, {:before, id2}} == valid_at(id1, "<" <> id2)
    assert {:ok, :current} == valid_at(id1, "@")
    assert {:ok, :head} == valid_at(id1, "0")
    assert {:ok, :tail} == valid_at(id1, "-1")
    assert {:error, "Invalid :at reference"} == valid_at(id1, "narf")
    assert {:error, "Invalid :at UUID (self?)"} == valid_at("id", "<id")
    assert {:error, "Invalid :at UUID (not uuid)"} == valid_at("x", "<not-a-uuid")
  end

  test "misc coverage" do
    assert :ok = valid_value(10)
    assert :ok = valid_expand_map(%{a: 1}, :a)
    assert :ok = valid_expand_list([1])
    assert {:error, "Too many values in data"} = valid_expand_list(Enum.map(1..33, & &1))
  end
end
