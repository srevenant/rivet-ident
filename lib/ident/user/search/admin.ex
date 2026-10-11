defmodule Rivet.Ident.User.Search.Admin do
  use Core.Context

  ##############################################################################
  ## legacy crap

  @soft_limit 25
  @hard_limit 100

  def sanitized_glob(match), do: String.downcase(Regex.replace(~r/[^a-z0-9 ]/i, match, ""))

  def search_results(filtered_query, base_query, args) do
    limit = get_limit(args)
    results = limit(filtered_query, ^limit) |> Repo.all()

    {:ok,
     %{
       total: Repo.aggregate(base_query, :count),
       matching: Repo.aggregate(filtered_query, :count),
       success: true,
       results: results
     }}
  end

  def get_limit(%{limit: limit}) when is_integer(limit) and limit < @hard_limit,
    do: limit

  def get_limit(_), do: @soft_limit

  ##############################################################################
  # admins searching users
  defp filter_matching(query, %{matching: match}) do
    case sanitized_glob(match) do
      "" ->
        query

      glob ->
        glob = "%#{glob}%"

        filter_email =
          from(e in Db.Ident.Email,
            where: e.user_id == parent_as(:user).id and ilike(e.address, ^glob)
          )

        filter_handle =
          from(h in Db.Ident.Handle,
            where: h.user_id == parent_as(:user).id and ilike(h.handle, ^glob)
          )

        where(
          query,
          [user: u],
          ilike(u.name, ^glob) or exists(filter_email) or exists(filter_handle)
        )
    end
  end

  defp filter_matching(query, _), do: query

  @doc """
  iex> {:error, _} = query_users(%{id: Ecto.UUID.generate()})
  iex> {:ok, _} = query_users(%{matching: "red"})
  """
  def query_users(%{id: id}), do: Db.Ident.User.one(id: id)

  def query_users(args) do
    base = from(u in Db.Ident.User, as: :user)

    # |> join(:right, [u],
    # e in Db.Ident.Email, on: e.user_id == as(:user).id, as: :email)
    # |> join(:right, [u, e], h in Db.Ident.Handle, on: h.user_id == as(:user).id, as: :handle)
    base
    |> order_by(desc: as(:user).last_seen, desc: as(:user).updated_at)
    |> filter_matching(args)
    |> search_results(base, args)
  end
end
