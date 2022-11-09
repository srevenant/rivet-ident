defmodule Cato.Data.Auth.UserDatas do
  alias Cato.Data.Auth
  use Unify.Ecto.Collection.Context

  def list_types(%Auth.User{id: id}, types) when is_list(types) do
    @repo.all(
      from(d in Auth.UserData,
        where: d.user_id == ^id and d.type in ^types
      )
    )
  end
end
