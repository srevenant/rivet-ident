defmodule Rivet.Data.Ident.Handle.Db do
  alias Rivet.Data.Ident
  use Rivet.Ecto.Collection.Context

  @doc """
  Check if handle is open, return double-error (internal/external msg)
  """
  def available(handle, user_id \\ nil) when is_binary(handle) do
    if String.length(handle) < 4 do
      {:error, "short handle", "Your handle should be at least 4 characters long"}
    else
      case Ident.Handle.one(handle: handle) do
        {:ok, %Ident.Handle{user_id: ^user_id}} ->
          {:ok, :current}

        {:ok, _} ->
          {:error, "existing handle not by user", "Sorry, that handle isn't available"}

        {:error, "Nothing found"} ->
          {:ok, :available}

        {:error, err} ->
          {:error, "unexected error=#{inspect(err)}", "Sorry, that handle isn't available"}
      end
    end
  end

  defp clean_handle(handle) when is_binary(handle) do
    String.split(handle, "@", parts: 2)
    |> Enum.at(0)
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9-]/, "-")
    |> String.replace(~r/-+/, "-")
    |> String.replace(~r/(^-|-$)/, "")
  end

  @chars String.graphemes("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
  defp randchar(), do: Enum.random(@chars)

  def gen_good_handle(handle) do
    handle = clean_handle(handle)

    case Ident.Handle.Db.available(handle) do
      {:error, _, _} ->
        gen_good_handle(handle <> randchar() <> randchar())

      {:ok, _available_msg} ->
        handle
    end
  end
end
