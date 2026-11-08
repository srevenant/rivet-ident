defmodule Rivet.Data.Tools do
  import Rivet.Guards

  def insert_at(:current, item, list), do: {:ok, list ++ [item]}
  def insert_at(:tail, item, list), do: {:ok, list ++ [item]}
  def insert_at(:head, item, list), do: {:ok, [item | list]}

  def insert_at({where, id}, item, list),
    do: insert_via_id(list, where, id, item, [])

  def insert_at(_, _, _), do: {:error, "Unsupported :at for insert"}

  ##############################################################################
  defp insert_via_id([head | rest], where, id, item, acc) do
    if head["id"] == id do
      if where == :after,
        do: {:ok, :lists.reverse(:lists.reverse(rest) ++ [item, head | acc])},
        else: {:ok, :lists.reverse(:lists.reverse(rest) ++ [head, item | acc])}
    else
      insert_via_id(rest, where, id, item, [head | acc])
    end
  end

  defp insert_via_id([], _, _, item, acc),
    do: {:ok, :lists.reverse([item | acc])}

  ##############################################################################
  def update_at(:current, {myid, key, value}, list) do
    Enum.reduce(list, {:not, []}, fn
      %{"id" => id} = me, {_, acc} when id == myid -> {:ok, [Map.put(me, key, value) | acc]}
      notme, {fwd, acc} -> {fwd, [notme | acc]}
    end)
    |> case do
      # then just add it to the end
      {:not, _} -> {:ok, list ++ [Map.new([{"id", myid}, {key, value}])]}
      {:ok, list} -> {:ok, Enum.reverse(list)}
    end
  end

  def update_at(:tail, {id, key, value}, list) do
    with {:ok, e, list} <- pop_from_list(list, id),
         do: {:ok, list ++ [Map.put(e, key, value)]}
  end

  def update_at(:head, {id, key, value}, list) do
    with {:ok, e, list} <- pop_from_list(list, id),
         do: {:ok, [Map.put(e, key, value) | list]}
  end

  def update_at(:up, {id, key, value}, list) when is_uuid(id) do
    case Enum.find_index(list, fn i -> i["id"] == id end) do
      0 ->
        {:ok, list}

      x ->
        {first, [me | last]} = Enum.split(list, x)
        me = Map.put(me, key, value)
        [before | first] = Enum.reverse(first)
        {:ok, Enum.reverse(first) ++ [me, before] ++ last}
    end
  end

  def update_at(:down, {id, key, value}, list) when is_uuid(id) do
    len = length(list) - 1

    case Enum.find_index(list, fn i -> i["id"] == id end) do
      # it is the last item
      ^len ->
        {:ok, list}

      x ->
        {first, [me, next | last]} = Enum.split(list, x)
        me = Map.put(me, key, value)
        {:ok, first ++ [next, me] ++ last}
    end
  end

  def update_at({where, at}, {id, key, value}, list) do
    with {:ok, e, list} <- pop_from_list(list, id),
         do: insert_via_id(list, where, at, Map.put(e, key, value), [])
  end

  def get_in_list(id, list), do: Enum.find(list, fn x -> x["id"] == id end)

  # #####
  # def update_in_place([%{id: id} = e | list], id), do: {:ok, list, e}
  # def update_in_place([pass | list], id), do: [pass | update_in_place(list, id)]
  # def update_in_place([], _), do: {:error, "Item not found in list?"}

  #####
  def pop_from_list(list, id) do
    case Enum.split_with(list, fn i -> i["id"] == id end) do
      {[item], rest} -> {:ok, item, rest}
      {[], _} -> {:error, "Item not found in list"}
      _ -> {:error, "Too many items with same id in list"}
    end
  end
end
