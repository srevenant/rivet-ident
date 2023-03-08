defmodule Rivet.Ident.UserData.Lib do
  alias Rivet.Ident
  use Rivet.Ecto.Collection.Context, model: Ident.UserData

  def list_types(%Ident.User{id: id}, types) when is_list(types) do
    @repo.all(
      from(d in Ident.UserData,
        where: d.user_id == ^id and d.type in ^types
      )
    )
  end
end
