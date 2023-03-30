defmodule Rivet.Ident.UserIdent.Lib do
  alias Rivet.Ident.User
  alias Rivet.Ident.UserIdent
  use Rivet.Ecto.Collection.Context, model: UserIdent

  def get(origin, key) do
    UserIdent.one(origin: origin, ident: key)
    |> case do
      {:error, _} ->
        :error

      found ->
        # touch the ident
        from(i in UserIdent, where: i.origin == ^origin and i.ident == ^key)
        |> UserIdent.update_all(set: [updated_at: DateTime.utc_now()])

        found
    end
  end

  def put(%User{id: id}, origin, key) when is_binary(origin) and is_binary(key) do
    %{user_id: id, origin: origin, ident: key}
    |> UserIdent.build()
    |> UserIdent.insert(on_conflict: :replace_all, conflict_target: [:origin, :ident])
  end
end
