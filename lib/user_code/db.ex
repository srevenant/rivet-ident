defmodule Cato.Data.Auth.UserCode.Db do
  alias Cato.Data.Auth
  alias Auth.UserCode
  use Unify.Ecto.Collection.Context

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

    from(c in Auth.UserCode, where: c.expires < ^now)
    |> Repo.delete_all()
  end

  def clear_all_codes(for_user_id, type) do
    from(c in Auth.UserCode,
      where:
        c.user_id == ^for_user_id and
          c.type == ^type
    )
    |> Repo.delete_all()
  end
end
