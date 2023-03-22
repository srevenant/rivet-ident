defmodule Rivet.Ident.User.Lib.Search do
  alias Rivet.Ident
  use Rivet.Ecto.Collection.Context, model: Ident.User
  import Ecto.Query

  def search(%{matching: match}, args) do
   match = String.downcase(Regex.replace(~r/[^a-z0-9]/i, match, ""))

   from(u in Ident.User,
     join: e in Ident.UserEmail,
     on: e.user_id == u.id,
     join: h in Ident.UserHandle,
     on: h.user_id == u.id,
     where: like(u.name, ^match) or like(h.handle, ^match) or like(e.address, ^match)
   )
   |> enrich_query_args(args)
   |> all()
  end
end
