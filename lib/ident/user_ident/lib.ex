defmodule Rivet.Data.Ident.UserIdent.Lib do
  alias Rivet.Data.Ident.User
  alias Rivet.Data.Ident.UserIdent
  use Rivet.Ecto.Collection.Context, model: UserIdent

  def get(origin, key) do
    UserIdent.one(origin: origin, ident: key)
    |> case do
      nil ->
        :error

      found ->
        # touch the ident
        from(i in UserIdent, where: i.origin == ^origin and i.ident == ^key)
        |> @repo.update_all(set: [updated_at: DateTime.utc_now()])

        {:ok, found}
    end
  end

  def put(%User{id: id}, origin, key) when is_binary(origin) and is_binary(key) do
    %{user_id: id, origin: origin, ident: key}
    |> UserIdent.build()
    |> @repo.insert(on_conflict: :replace_all, conflict_target: [:origin, :ident])
  end
end
