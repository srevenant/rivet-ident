defmodule Rivet.Ident.User.Search do
  use Rivet.Ident
  alias Rivet.Search.{Tools, Filter, Results}

  @schema [
    name: [type: :glob, join: &__MODULE__.join_to_handle/3, order: &__MODULE__.order_name/4],
    services: [type: :uuid, list: :in, order: false]
    # allows: [type: :string, list: :in, order: false]
  ]

  use Rivet.Search, schema: @schema

  @impl Rivet.Search
  def base_query(opts) do
    from(u in User,
      as: :user,
      where: fragment("jsonb_exists(?, 'LIB')", u.sites),
      order_by: [desc: u.last_seen]
    )
  end

  ##############################################################################
  def join_to_handle(_, q, state), do: {:ok, Tools.join_relation(q, :user, :handle), state}

  def order_name(state, ord, _, _),
    do: [{:name, {ord, :user, :name}} | state.order]

  ##############################################################################
  @impl Rivet.Search
  def filter_expr({:name, %{v, x: :is}}) when not_empty_str(v),
    do: {:ok, dynamic([user: u, handle: h], ilike(u.name, ^v) or ilike(h.handle, ^v))}

  # def filter_expr({:allows, %{x: :is, v: ["libmail"]}}),
  #   do: {:ok, dynamic([user: u], fragment("jsonb_exists(?, 'LIB')", u.sites))}

  def filter_expr({:services, %{x: :is, v: [_ | _] = ids}}) do
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

  def filter_expr(_), do: {:error, "Unrecognized filter"}
end
