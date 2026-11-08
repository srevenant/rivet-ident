defmodule Rivet.Data.Valid do
  import Rivet.Guards

  @maxlen_key 64
  @maxlen_value 2048
  @max_values 32

  #####
  def invalid_at_id(id, id, _), do: {:error, "Invalid :at UUID (self?)"}
  def invalid_at_id(_, at, _) when not is_uuid(at), do: {:error, "Invalid :at UUID (not uuid)"}
  def invalid_at_id(_, at, good), do: {:ok, {good, at}}

  def valid_at(id, "<" <> at), do: invalid_at_id(id, at, :before)
  def valid_at(id, ">" <> at), do: invalid_at_id(id, at, :after)
  def valid_at(_, "@"), do: {:ok, :current}
  def valid_at(_, "0"), do: {:ok, :head}
  def valid_at(_, "-1"), do: {:ok, :tail}
  def valid_at(_, "+"), do: {:ok, :up}
  def valid_at(_, "-"), do: {:ok, :down}
  def valid_at(_, _), do: {:error, "Invalid :at reference"}

  # def build_change_list("@"
  #        do:
  #
  #        # {:ok, curval, position} <- get_current(pdata.value, id, at),
  #        # :ok <- valid_expand_list(pdata.value),
  #        # :ok <- valid_expand_map(curval),
  #        # do: List.replace_at(pdata.value, position, curval)
  # end

  def get_list_from(%{"list" => list}), do: {:ok, list}
  def get_list_from(_), do: {:ok, []}

  # This shape validation is to try and avoid people abusing the API and over-stuffing
  # the data with random crap to bloat the DB.
  #
  # The max's are defaults; additional functions can be added for specialized filtering
  # based on data type
  # def get_current(list, id) do
  #   Enum.reduce_while(list, 0, fn
  #     item, x when item.id == id -> {:halt, {item, x}}
  #     _, x -> {:cont, x + 1}
  #   end)
  #   |> case do
  #     x when is_number(x) -> {%{id: id}, -1}
  #     {_, _} = pass -> pass
  #   end
  # end
  #
  # # def build_change(%Data{} = pdata, %{id: id, key: key, value: value})
  #      # when not_empty_str(id) do
  #   v = Map.get(pdata.value, id, %{}) |> Map.put(key, value)
  #
  #   {:ok, Map.put(pdata.value, id, v), {key, value}}
  # end

  # def build_change(%Data{} = pdata, %{key: key, value: value}),

  # def get_sub_data(%Data{} = pd, id),
  #   do: get_sub_data(Data.type_depth(pd.type), pd.value, id)
  #
  # def get_sub_data(:map, value, _), do: {:map, value}
  # def get_sub_data(:list, value, id), do: {:list,
  # def valid_data(%Data{depth: :map} = pdata, nil, %{key: key, value: value}),
  #   do: valid_key_value(key, value)
  #
  # def valid_data(%Data{depth: :list} = pdata, id, %{key: key, value: value}) when is_uuid(id),
  #   do: valid_list_value(pdata.value, id, key, value)
  #
  # def valid_data(_, _, _), do: {:error, "Invalid data inputs"}

  ######
  def valid_key_value(key, val) do
    with :ok <- valid_value(val), do: valid_key(key)
  end

  ######
  def valid_key(key) when is_binary(key) and byte_size(key) <= @maxlen_key, do: :ok
  def valid_key(_), do: {:error, "Invalid key for data"}

  ######
  def valid_value(val) when is_binary(val) do
    if byte_size(val) <= @maxlen_value, do: :ok, else: {:error, "Value is too long for data"}
  end

  def valid_value(val) when is_number(val), do: :ok
  def valid_value(_), do: {:error, "Invalid value type"}

  ######
  def valid_expand_map(data, key) when is_map_key(data, key), do: :ok
  def valid_expand_map(data, _) when map_size(data) < @max_values, do: :ok
  def valid_expand_map(_, _), do: {:error, "Too many values in data"}

  def valid_expand_list(list) when Kernel.length(list) < @max_values, do: :ok
  def valid_expand_list(_), do: {:error, "Too many values in data"}

  #
  #     # Data.type_depth(pdata.type) == 1 -> {:error, "Data type '#{type}' too deep"}
  #     # length(map) > @max_values -> {:error, "Too many values in data"}
  #     true -> valid_data(pdata, type, :deep, key, value)
  #   end
  # end

  # def valid_data(%Data{} = pdata, xid, key, v)
  #     when (xid in [nil, :deep] and not_empty_str(key) and is_binary(v)) or is_number(v) do
  #   cond do
  #     xid != :deep and Data.type_depth(type) == 2 -> {:error, "Data type '#{type}' too shallow"}
  #     byte_size(key) > @maxlen_key -> {:error, "Key is too long for data"}
  #     is_binary(v) and byte_size(v) > @maxlen_value -> {:error, "Value is too long for data"}
  #     map_size(pdata.value) > @max_values -> {:error, "Too many values in data"}
  #     true -> :ok
  #   end
  # end
end
