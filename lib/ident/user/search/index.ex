defmodule Rivet.Ident.User.Search do
  use Core.Context
  alias Core.Search.{Tools, Filter, Results}
  alias __MODULE__, as: Self

  @col_spec %{
    name: %{type: :glob, join: &Self.join_to_handle/3, order: &Self.order_name/4},
    services: %{type: :uuid, list: :in, order: false}
    # allows: %{type: :string, list: :in, order: false}
  }

  @default []

  def search(%{filter: filter} = args) do
    case build_search_query(filter) do
      {:ok, query} -> Tools.query_with_substatus(query, args)
      error -> Results.substatus_results(error)
    end
  end

  def build_search_query(filters, default_filter \\ @default) do
    from(u in Db.Ident.User,
      as: :user,
      where: fragment("jsonb_exists(?, 'LIB')", u.sites),
      order_by: [desc: u.last_seen]
    )
    |> Filter.enrich_search_query(&filter_expr/1, @col_spec, filters, default_filter)
  end

  ##############################################################################
  def join_to_handle(_, q, state), do: {:ok, Tools.join_relation(q, :user, :handle), state}

  def order_name(state, ord, _, _),
    do: [{:name, {ord, :user, :name}} | state.order]

  ##############################################################################
  defp filter_expr({:name, %{v, x: :is}}) when not_empty_str(v),
    do: {:ok, dynamic([user: u, handle: h], ilike(u.name, ^v) or ilike(h.handle, ^v))}

  # defp filter_expr({:allows, %{x: :is, v: ["libmail"]}}),
  #   do: {:ok, dynamic([user: u], fragment("jsonb_exists(?, 'LIB')", u.sites))}

  defp filter_expr({:services, %{x: :is, v: [_ | _] = ids}}) do
    tag_count = length(ids)

    subfilter =
      from(tp in Db.TagUser,
        where:
          tp.user_id == parent_as(:user).id and
            tp.tag_id in ^ids and tp.type == :service and tp.public,
        group_by: tp.user_id,
        having: count(tp.tag_id, :distinct) == ^tag_count,
        select: 1
      )

    {:ok, dynamic([], exists(subfilter))}
  end

  defp filter_expr(_), do: {:error, "Unrecognized filter"}
end
