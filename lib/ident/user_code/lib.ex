defmodule Rivet.Data.Ident.UserCode.Lib do
  alias Rivet.Data.Ident
  alias Ident.UserCode
  use Rivet.Ecto.Collection.Context, model: UserCode

  def generate_code(for_user_id, type, expiration_minutes, meta \\ %{}) when is_atom(type) do
    code =
      Ecto.UUID.generate()
      |> String.replace(~r/[-IO0]+/i, "")
      |> String.slice(1..8)
      |> String.upcase()

    case UserCode.one(code: code) do
      {:ok, _} ->
        generate_code(for_user_id, type, expiration_minutes)

      {:error, _} ->
        case UserCode.create(%{
               user_id: for_user_id,
               code: code,
               type: type,
               meta: meta,
               expires: Timex.now() |> Timex.shift(minutes: expiration_minutes)
             }) do
          {:ok, code} ->
            {:ok, code}

          {:error, chgset} ->
            IO.inspect(chgset, label: "Cannot generate code?")
            {:error, "cannot generate code"}
        end
    end
  end

  # housekeeper
  def clear_expired_codes() do
    now = Timex.now()

    from(c in UserCode, where: c.expires < ^now)
    |> @repo.delete_all()
  end

  def clear_all_codes(for_user_id, type) do
    from(c in UserCode,
      where:
        c.user_id == ^for_user_id and
          c.type == ^type
    )
    |> @repo.delete_all()
  end
end
