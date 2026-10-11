defmodule Rivet.Ident.User.Search.LegacyPublic do
  use Core.Context
  alias Core.Search.Tools
  alias __MODULE__, as: Public

  ##############################################################################
  ## legacy crap

  #  @soft_limit 25
  #  @hard_limit 100

  # def sanitized_glob(match), do: String.downcase(Regex.replace(~r/[^a-z0-9 ]/i, match, ""))

  # def search_results(filtered_query, base_query, args) do
  #   limit = get_limit(args)
  #   results = limit(filtered_query, ^limit) |> Repo.all()
  #
  #   {:ok,
  #    %{
  #      total: Repo.aggregate(base_query, :count),
  #      matching: Repo.aggregate(filtered_query, :count),
  #      success: true,
  #      results: results
  #    }}
  # end

  # def get_limit(%{limit: limit}) when is_integer(limit) and limit < @hard_limit,
  #   do: limit
  #
  # def get_limit(_), do: @soft_limit

  defstruct joins: %{}, query: nil, args: %{}

  ##############################################################################
  @doc """
  iex> {:ok, %{status: %{success: false, message: "no user found"}}} = search(%{id: Ecto.UUID.generate()})
  iex> {:ok, %{status: %{success: true, matching: 0}}} = search(%{name: "red"})
  """
  def search(%{id: id}) do
    case Db.Ident.User.one(id: id) do
      {:ok, u} -> {:ok, %{status: %{success: true, matching: 1}, results: [u]}}
      _ -> {:ok, %{status: %{success: false, message: "no user found"}}}
    end
  end

  def search(args) do
    with %Public{} = base_state <- start_query(args),
         %Public{} = state <- filter_name(base_state),
         %Public{} = state <- filter_types(state),
         %Public{} = state <- filter_services(state),
         %Public{} = state <- filter_site(state) do
      # %Public{} = state <- filter_roles(state),
      # %Public{} = state <- filter_skills(state),
      # %Public{} = state <- filter_data(state),
      # %Public{} = state <- filter_tags(state),
      state.query
      |> order_by([user: user], desc: user.last_seen)
      |> Tools.query_with_substatus(args)
    end
  end

  defp start_query(args) do
    with {:ok, args} <- clean_args(Map.to_list(args), []),
         do: %Public{
           query: from(u in Db.Ident.User, as: :user),
           args: args
         }
  end

  ################################################################################
  defp clean_args([{:name, name} | rest], out) do
    case Regex.replace(~r/[^a-z0-9 ]/i, name, "") do
      name when byte_size(name) > 0 -> cleaned("%#{name}%", :name, rest, out)
      _ -> clean_args(rest, out)
    end
  end

  defp clean_args([{:types, types} | rest], out) when is_list(types) and length(types) > 0,
    # could trim list of nils
    do: cleaned(types, :types, rest, out)

  # should come in as UUIDs
  defp clean_args([{:services, []} | rest], out), do: clean_args(rest, out)

  defp clean_args([{:services, svcs} | rest], out) when is_list(svcs) do
    case Enum.find(svcs, fn id -> not is_uuid(id) end) do
      nil -> cleaned(svcs, :services, rest, out)
      _ -> {:error, :args}
    end
  end

  # defp clean_args([{:site, ref} | rest], out) when not_empty_str(ref),
  #   do: cleaned(ref, :site, rest, out)

  # unrecognized or invalid — ignore
  defp clean_args([_ | rest], out), do: clean_args(rest, out)

  defp clean_args([], out), do: {:ok, Map.new(out)}

  defp cleaned(value, key, rest, out), do: clean_args(rest, [{key, value} | out])

  ##############################################################################
  defp filter_site(%Public{args: %{site: site}} = state) do
    state
    |> add_to_query(fn q ->
      where(q, [user: user], fragment("CAST(?.sites->? AS int) > 0", user, ^site))
    end)
  end

  defp filter_site(state), do: state

  ##############################################################################
  defp filter_name(%Public{args: %{name: name}} = state) do
    state
    |> add_join_handle()
    |> add_to_query(fn q ->
      or_where(
        q,
        [user: user, handle: handle],
        like(user.name, ^name) or like(handle.handle, ^name)
      )
    end)
  end

  defp filter_name(state), do: state

  ##############################################################################
  defp filter_types(%Public{args: %{types: types}} = state) do
    Enum.reduce(types, add_join_data(state), fn type, state ->
      add_to_query(state, fn q ->
        or_where(q, [data: d], d.type == ^type and fragment("?.value->? IS NOT NULL", d, ^type))
      end)
    end)
  end

  defp filter_types(state), do: state

  ##############################################################################
  defp filter_services(%Public{args: %{services: services}} = state),
    do: filter_tags(state, services, :service)

  defp filter_services(state), do: state

  defp filter_tags(state, tags, type) do
    Enum.reduce(tags, add_join_tags(state), fn tag_id, state ->
      add_to_query(state, fn q ->
        where(q, [tag: tag], tag.type == ^type and tag.tag_id == ^tag_id and tag.public)
      end)
    end)
  end

  ##############################################################################
  # filter helpers
  defp add_to_query(state, func), do: %Public{state | query: func.(state.query)}

  ##############################################################################
  # only add join if it isn't added
  defp add_join(%{joins: joins} = state, name, _) when is_map_key(joins, name), do: state

  defp add_join(state, name, func),
    do: %Public{state | query: func.(state.query), joins: Map.put(state.joins, name, [])}

  defp add_join_data(state) do
    add_join(state, :data, fn q ->
      join(q, :left, [user: user], data in assoc(user, :data), as: :data)
    end)
  end

  defp add_join_handle(state) do
    add_join(state, :handle, fn q ->
      join(q, :left, [user: user], handle in assoc(user, :handle), as: :handle)
    end)
  end

  defp add_join_tags(state) do
    add_join(state, :tag, fn q ->
      join(q, :left, [user: user], tag in assoc(user, :tags), as: :tag)
    end)
  end
end
