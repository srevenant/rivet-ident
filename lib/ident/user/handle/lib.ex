defmodule Rivet.Ident.Handle.Lib do
  alias Rivet.Ident
  use Rivet.Ecto.Collection.Context, model: Ident.Handle

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

        {:error, :not_found} ->
          {:ok, :available}

        {:ok, _} ->
          {:error, "existing handle not by user", "Sorry, that handle isn't available"}

        {:error, err} ->
          {:error, "unexpected error=#{inspect(err)}", "Sorry, that handle isn't available"}
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

    case Ident.Handle.Lib.available(handle) do
      {:error, _, _} ->
        gen_good_handle(handle <> randchar() <> randchar())

      {:ok, _available_msg} ->
        handle
    end
  end
end
