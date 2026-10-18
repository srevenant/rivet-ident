defmodule Rivet.Ident.User.ExtId.Lib do
  use Rivet.Ident
  use Rivet.Ecto.Collection.Context, model: User.ExtId

  def get(origin, key) do
    with {:ok, ext_id} <- User.ExtId.one(origin: origin, extid: key) do
      from(i in User.ExtId, where: i.origin == ^origin and i.extid == ^key)
      |> User.ExtId.update_all(set: [updated_at: DateTime.utc_now()])

      {:ok, ext_id}
    end
  end

  def put(%User{id: id}, origin, key) when is_binary(origin) and is_binary(key) do
    case User.ExtId.one(origin: origin, extid: key) do
      {:ok, %{user_id: ^id}} = pass -> pass
      {:ok, _} -> {:error, "ExtId exists"}
      {:error, :not_found} -> User.ExtId.create(%{user_id: id, origin: origin, extid: key})
    end
  end
end
