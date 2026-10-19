defmodule Rivet.Ident.Handle.Lib do
  use Rivet.Ident
  alias Rivet.Auth
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
          {:error, "existing handle", "Sorry, that handle isn't available"}

        {:error, err} ->
          # DB level errors
          # coveralls-ignore-next-line
          {:error, "unexpected error=#{inspect(err)}", "Sorry, that handle isn't available"}
      end
    end
  end

  @max 32
  @max0 @max - 1
  defp clean_handle!(handle) when is_binary(handle) do
    String.split(handle, "@", parts: 2)
    |> Enum.at(0)
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9-]/, "-")
    |> String.replace(~r/-+/, "-")
    |> String.replace(~r/(^-|-$)/, "")
    |> String.slice(0..@max0//1)
  end

  defp clean_handle!(_), do: ""

  def clean_handle(handle) do
    case clean_handle!(handle) do
      handle when not_empty_str(handle) -> {:ok, handle}
      _ -> :error
    end
  end

  @chars String.graphemes("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
  defp randchar(), do: Enum.random(@chars)

  ##############################################################################
  def add_handle(%Auth.Domain{user: %{id: user_id}} = auth) when is_uuid(user_id) do
    with {:ok, handle} <- derive_handle(auth), do: Handle.create(%{handle, user_id})
  end

  ##############################################################################
  def gen_good_handle!(handle) do
    handle = clean_handle!(handle)

    case Ident.Handle.Lib.available(handle) do
      {:error, _, _} ->
        handle =
          if String.length(handle) >= @max - 2 do
            # start over and give us some extra room to play with
            shorter = Kernel.trunc(@max / 2)
            String.slice(handle, 0..shorter//1)
          else
            handle
          end

        gen_good_handle!(handle <> randchar() <> randchar())

      {:ok, _available_msg} ->
        handle
    end
  end

  ##############################################################################
  def derive_handle(%Auth.Domain{} = auth),
    do: derive_handle_(auth, [&get_from_input/1, &get_from_email/1, &get_from_name/1])

  defp derive_handle_(auth, [next | rest]) do
    case next.(auth) do
      {:ok, handle} -> {:ok, gen_good_handle!(handle)}
      :error -> derive_handle_(auth, rest)
    end
  end

  defp derive_handle_(_, []),
    do: {:ok, gen_good_handle!(randchar() <> randchar() <> randchar() <> randchar())}

  defp get_from_input(%Auth.Domain{input: %{handle}}), do: {:ok, handle}
  defp get_from_input(_), do: :error

  defp get_from_email(%Auth.Domain{input: %{email: %{address}}}), do: {:ok, address}
  defp get_from_email(_), do: :error

  defp get_from_name(%Auth.Domain{user: %{name}}), do: {:ok, name}
  defp get_from_name(_), do: :error
end
