defmodule Rivet.Data.Ident.UserData.Db do
  alias Rivet.Data.Ident
  use Rivet.Ecto.Collection.Context

  def list_types(%Ident.User{id: id}, types) when is_list(types) do
    @repo.all(
      from(d in Ident.UserData,
        where: d.user_id == ^id and d.type in ^types
      )
    )
  end
end
