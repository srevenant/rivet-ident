defmodule Rivet.Ident.User.ExtId.Lib do
  use Rivet.Ident
  use Rivet.Ecto.Collection.Context, model: User.ExtId

  def get(origin, key) do
    User.ExtId.one(origin: origin, extid: key)
    |> case do
      {:error, _} ->
        :error

      found ->
        # touch the extid
        from(i in User.ExtId, where: i.origin == ^origin and i.extid == ^key)
        |> User.ExtId.update_all(set: [updated_at: DateTime.utc_now()])

        found
    end
  end

  def put(%User{id: id}, origin, key) when is_binary(origin) and is_binary(key) do
    %{user_id: id, origin: origin, extid: key}
    |> User.ExtId.build()
    |> User.ExtId.insert(on_conflict: :replace_all, conflict_target: [:origin, :extid])
  end
end
