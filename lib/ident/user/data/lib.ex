defmodule Rivet.Ident.User.Data.Lib do
  alias Rivet.Ident
  use Rivet.Ecto.Collection.Context, model: Ident.User.Data

  def list_types(%Ident.User{id: id}, types) when is_list(types) do
    from(d in Ident.User.Data,
      where: d.user_id == ^id and d.type in ^types
    )
    |> Ident.User.Data.all!()
  end
end
