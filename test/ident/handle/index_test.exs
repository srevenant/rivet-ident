defmodule Rivet.Ident.Test.Ident.User.Handle.IndexTest do
  use Rivet.Ident.Support.Case, async: true
  alias Rivet.Auth
  alias Rivet.Ident.Handle
  alias Handle.Lib

  test "model tests" do
    assert %Handle{id} = insert(:ident_handle)
    assert is_uuid(id)
    assert %Handle{id: ^id} = Handle.one!(id: id)
    params = params_with_assocs(:ident_handle)
    assert {:ok, %Handle{} = x} = Handle.create(params)
    assert {:ok, _} = Handle.delete(x)
  end

  test "Lib" do
    assert :error = Lib.clean_handle(:narf)
    assert {:ok, "good"} = Lib.clean_handle("good")

    assert {:ok, handle} = Lib.derive_handle(%Auth.Domain{})
    assert String.length(handle) == 4

    assert {:ok, "narfinator"} = Lib.derive_handle(%Auth.Domain{user: %{name: "narfinator"}})

    long = Ecto.UUID.generate() |> String.replace("-", "")
    assert {:ok, long} = Lib.clean_handle(long <> long)
    insert(:ident_handle, handle: long)
    assert Lib.gen_good_handle!(long) != long
  end
end
