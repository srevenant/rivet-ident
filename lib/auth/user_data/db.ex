defmodule Rivet.Data.Auth.UserData.Db do
  alias Rivet.Data.Auth
  use Rivet.Ecto.Collection.Context

  def list_types(%Auth.User{id: id}, types) when is_list(types) do
    @repo.all(
      from(d in Auth.UserData,
        where: d.user_id == ^id and d.type in ^types
      )
    )
  end
end
