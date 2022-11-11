defmodule Rivet.Data.Auth.UserSearch do
  alias Rivet.Data.Auth
  use Unify.Ecto.Collection.Context
  import Ecto.Query

  ##############################################################################
  # various utility funcitons
  defp repo_all(clauses), do: {:ok, @repo.all(clauses)}

  defp and_exprs([elem | elems]) do
    Enum.reduce(elems, elem, fn e, a ->
      dynamic([], ^a and ^e)
    end)
  end

  defp join_if(state, key, func) do
    exprs = Map.get(state, key, [])

    if length(exprs) > 0 do
      %{state | query: func.(state.query)}
    else
      state
    end
  end

  defp append(value, key, state) do
    Map.put(state, key, state[key] ++ [value])
  end

  defp drop_arg(%{args: args} = state, key),
    do: %{state | args: Map.delete(args, key)}

  # defp tags_label_to_id(tags, type) do
  #   Enum.reduce(tags, [], fn label, acc ->
  #     case acc do
  #       {:error, _} = err ->
  #         err
  #
  #       list ->
  #         with {:ok, tag} <- Auth.Tag.one(label: label, type: type) do
  #           list ++ [tag.id]
  #         else
  #           _ ->
  #             IO.inspect(label, label: "CANNOT FIND TAG")
  #         end
  #     end
  #   end)
  # end

  defp filter_tags(state, tags, type) do
    [
      dynamic([tag: t], t.type == ^type),
      Enum.reduce(tags, dynamic(false), fn id, expr ->
        dynamic([tag: t], ^expr or t.tag_id == ^id)
      end)
    ]
    |> and_exprs
    |> append(:tags, state)
  end

  ##############################################################################
  def search(%{id: id}, _) do
    Auth.User.one(id: id)
  end

  def search(args, user) do
    %{
      user: [],
      data: [],
      tags: [],
      args: args,
      caller: user,
      query: from(u in Auth.User, as: :user)
    }
    |> filters
    |> join_if(:data, fn q ->
      from(u in q,
        join: d in Auth.UserData,
        as: :data,
        on: u.id == d.user_id and d.type == ^:toggles
      )
    end)
    # |> join_if(:tags, fn q ->
    #   from(u in q, join: t in Auth.TagUser, as: :tag, on: u.id == t.user_id)
    # end)
    |> query
    |> from(limit: 15, order_by: [desc: :updated_at])
    |> repo_all
  end

  #############################################################################
  # order is important for optimizing.  don't adjust order unless you really
  # understand the impact.  This is why it's a reducing pattern-matched function
  # set, vs a reduction on the params

  ## # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
  defp filters(%{args: %{name: name}} = state) when is_binary(name) do
    name = Regex.replace(~r/[^a-z0-9]/i, name, "")

    if String.length(name) > 0 do
      name = "%#{name}%"

      dynamic([user: u], like(u.name, ^name))
      |> append(:user, state)
    else
      state
    end
    |> drop_arg(:name)
    |> filters
  end

  ## # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
  defp filters(%{args: %{types: types}} = state) when is_list(types) and length(types) > 0 do
    # or each one
    Enum.reduce(types, dynamic(false), fn need, expr ->
      dynamic([data: d], ^expr or fragment("value->? IS NOT NULL", ^need))
    end)
    |> append(:data, state)
    |> drop_arg(:types)
    |> filters
  end

  # ## # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
  # defp filters(%{args: %{roles: roles}} = state) when is_list(roles) and length(roles) > 0 do
  #   filter_tags(state, tags_label_to_id(roles, :role), :role)
  #   |> drop_arg(:roles)
  #   |> filters
  # end

  ## # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
  defp filters(%{args: %{skills: skills}} = state) when is_list(skills) and length(skills) > 0 do
    filter_tags(state, skills, :skill)
    |> drop_arg(:skills)
    |> filters
  end

  ## # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
  defp filters(state), do: state

  ##############################################################################
  defp query(%{args: %{tenant_id: _}, user: user, data: data, tags: tags} = state)
       when length(data) > 0 and length(tags) > 0 do
    state.query |> where(^and_exprs(user ++ data ++ tags))
  end

  defp query(%{args: %{tenant_id: _}, user: user, tags: tags} = state) when length(tags) > 0 do
    state.query |> where(^and_exprs(user ++ tags))
  end

  defp query(%{args: %{tenant_id: _}, user: user, data: data} = state) when length(data) > 0 do
    state.query |> where(^and_exprs(user ++ data))
  end

  defp query(%{args: %{tenant_id: _}, user: user} = state) when length(user) > 0 do
    state.query |> where(^and_exprs(user))
  end

  defp query(%{args: %{tenant_id: _}, user: [], data: [], tags: []} = state),
    do: state.query

  defp query(state) do
    IO.inspect(%{user: state.user, tags: state.tags, data: state.data, args: state.args},
      label: "FAILED TO MATCH"
    )
  end
end
