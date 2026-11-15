defmodule Rivet.Ident.User.Code.Lib do
  use Rivet.Ident
  use Rivet.Ecto.Collection.Context, model: User.Code

  def reset_generate(for_user_id, type, meta \\ %{}) do
    clear_all_codes(for_user_id, type)
    expire = Application.get_env(:core, :user_code_expires)[type] || 60
    generate_code(for_user_id, type, expire, meta)
  end

  def generate_code(for_user_id, type, expiration_minutes, meta \\ %{}) when is_atom(type) do
    code =
      Ecto.UUID.generate()
      |> String.replace(~r/[-IO0]+/i, "")
      |> String.slice(1..8)
      |> String.upcase()

    case User.Code.one(code: code) do
      {:ok, _} ->
        # coveralls-ignore-next-line
        generate_code(for_user_id, type, expiration_minutes, meta)

      {:error, _} ->
        case User.Code.create(%{
               user_id: for_user_id,
               code: code,
               type: type,
               meta: meta,
               expires: DateTime.utc_now() |> DateTime.shift(minute: expiration_minutes)
             }) do
          {:ok, code} ->
            {:ok, code}

          {:error, chgset} ->
            # coveralls-ignore-next-line
            IO.inspect(chgset, label: "Cannot generate code?")
            {:error, "cannot generate code"}
        end
    end
  end

  def get_valid(code) do
    with {:ok, code} <- User.Code.one(code: code) do
      if DateTime.before?(DateTime.utc_now(), code.expires) do
        {:ok, code}
      else
        {:error, "Code Expired"}
      end
    end
  end

  # housekeeper
  def clear_expired_codes() do
    now = DateTime.utc_now()

    from(c in User.Code, where: c.expires < ^now)
    |> User.Code.delete_all()
  end

  def clear_all_codes(for_user_id, type) do
    from(c in User.Code, where: c.user_id == ^for_user_id and c.type == ^type)
    |> User.Code.delete_all()
  end
end
