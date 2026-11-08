defmodule Rivet.Data do
  @moduledoc """

  Data updates supporting deep maps or positional lists. Could be an independent
  lib and maybe some day will, but for now comes with rivet_ident.

  update/remove args:

    if depth=:list then:  %{key: key, value: value, at: at}
    if depth=:map then:   %{key: key, value: value}

    where 'at' with a list is the various things below; for maps it is ignored

  NOTES

  ID is required if the data type is a :list (see model's type_depth function)

  AT is OPTIONAL and only used to place or move the item within the list,
  values as shown:

    "0" — beginning
    "@" — stay where it is, or -1 if it is a create (append)
    "-1" — end
    ">UUID" — 36-char UUID; put this after UUID
    "<UUID" — 36-char UUID; put this before UUID
    "+" — go up one
    "-" - go down one

  ( by default at is "@" )

  MIGRATION:

  delete from user_datas where type = 0
  delete from user_datas where type >= 9

  """
  import Rivet.Data.Tools
  import Rivet.Data.Valid
  import Rivet.Guards
  import Rivet.Ecto.DefEnum
  import Ecto.Query

  @doc """
  Depths:
    :map (1) — one level deep
    :list (2) — ordered list of sub-objs

    ## maybe if needed in future...
    :sub (2) — unordered map of sub-objs where id is key in sub map
  """
  # coveralls-ignore-next-line
  defenum(Depth, map: 0, list: 1)
  @callback enrich_depth(data :: map()) :: {:ok, data :: map()}

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      import Rivet.Utils.Module

      ### Opts:
      #
      # * :types    EctoEnum for model types field
      #   :table    "{snake_origin}_data" or alt name (full)
      #   :table_fk "{snake_origin}_id"
      #
      # *required

      @data_model __MODULE__
      @origin_model mod_parent(@data_model)
      @table_name Keyword.get(opts, :table, "#{mod_to_name(@origin_model)}_datas")
      @origin_name Keyword.get(opts, :origin, mod_to_name(@origin_model))
      @origin_fk String.to_atom("#{@origin_name}_id")
      # @origins String.to_atom("#{@origin_name}s")
      @types Keyword.get(opts, :types)

      @behaviour Rivet.Data

      ##########################################################################
      use Rivet.Ident
      use TypedEctoSchema
      use Rivet.Ecto.Model

      typed_schema "#{@table_name}" do
        belongs_to(@origin_name, @origin_model, type: :binary_id, foreign_key: @origin_fk)
        field(:type, @types)
        field(:value, :map, default: %{})
        field(:depth, Rivet.Data.Depth, virtual: true, default: :map)
        timestamps()
      end

      use Rivet.Ecto.Collection,
        not_found: :atom,
        required: [@origin_fk, :type, :value],
        update: [:value],
        foreign_keys: [@origin_fk],
        unique: [[@origin_fk, :type]]

      ##########################################################################
      def data_update(args),
        do: Rivet.Data.update(@data_model, @origin_fk, args[@origin_fk], args)

      def data_remove(args),
        do: Rivet.Data.remove(@data_model, @origin_fk, args[@origin_fk], args)

      def upsert_for_origin(o_id, d_type, key, value) when is_uuid(o_id),
        do:
          Rivet.Data.upsert_for_origin(
            @origin_model,
            @data_model,
            o_id,
            @origin_fk,
            d_type,
            key,
            value
          )

      def build_remove(%@data_model{} = data, args), do: Rivet.Data.build_remove(data, args)

      def build_change(%@data_model{} = data, id, args),
        do: Rivet.Data.build_change(data, id, args)

      def all_of_types(%@origin_model{id: id}, types),
        do: Rivet.Data.all_of_types(@repo, @data_model, @origin_fk, id, types)

      def get_by_type(%@origin_model{id: id} = data, type),
        do: Rivet.Data.get_by_type(@repo, @data_model, @origin_fk, id, type)

      ## helper with enrich depth
      def data_is_list(d), do: {:ok, %{d | depth: :list}}

      @impl true
      def enrich_depth(d), do: {:ok, %{d | depth: :map}}
      defoverridable enrich_depth: 1
    end
  end

  ##############################################################################
  def update(module, key, origin_id, %{type: _} = args) do
    with {:ok, data} <- get_data(module, key, origin_id, args.type),
         {:ok, changed} <- build_change(data, args[:id], args),
         {:ok, data} <- module.update(data, %{value: changed}),
         do: {:ok, data}
  end

  def remove(module, key, origin_id, %{type: _} = args) do
    with {:ok, data} <- get_data(module, key, origin_id, args.type),
         {:ok, changed} <- build_remove(data, args),
         {:ok, data} <- module.update(data, %{value: changed}),
         do: {:ok, data}
  end

  @doc """

  Different from update; doesn't support lists, only maps

  It also touches the origin module as an update

  """
  def upsert_for_origin(origin_module, data_module, o_id, o_key, d_type, key, value) do
    claims = [{o_key, o_id}, {:type, d_type}]

    case data_module.one(claims) do
      {:ok, data} ->
        data_module.update(data, %{value: Map.put(data.value, key, value)})

      {:error, :not_found} ->
        d_value = Map.new([{key, value}])
        data_module.create(Map.new(claims ++ [{:value, d_value}]))
    end
    |> tap(fn
      {:ok, _} -> origin_module.touch(o_id)
      # errors are DB level, so don't touch the parent object; this is a tap so
      # the error will still propagate
      # coveralls-ignore-next-line
      _ -> :ok
    end)
  end

  ################################################################################
  def build_remove(%{depth: :list} = data, %{id: id}) when not_empty_str(id) do
    with {:ok, list} <- get_list_from(data.value),
         {:ok, _, list} <- pop_from_list(list, id),
         do: {:ok, %{"list" => list}}
  end

  def build_remove(%{depth: :map} = data, %{key: key}),
    do: {:ok, Map.delete(data.value, key)}

  # coveralls-ignore-next-line
  def build_remove(_, _, _), do: {:error, "Invalid args to remove in data"}

  ##############################################################################
  # create when id is nil
  @bogus_id "-"
  def build_change(%{depth: :list} = data, nil, %{key: key, value: value, at: at}) do
    with :ok <- valid_key_value(key, value),
         {:ok, where} <- valid_at(@bogus_id, at),
         {:ok, list} <- get_list_from(data.value),
         :ok <- valid_expand_list(list),
         item <- Map.new([{"id", Ecto.UUID.generate()}, {key, value}]),
         {:ok, data} <- insert_at(where, item, list) do
      {:ok, %{"list" => data}}
    end
  end

  # update
  def build_change(%{depth: :list} = data, id, %{key: key, value: value, at: at})
      when not_empty_str(id) do
    with :ok <- valid_key_value(key, value),
         {:ok, where} <- valid_at(id, at),
         {:ok, list} <- get_list_from(data.value),
         {:ok, updated} <- update_at(where, {id, key, value}, list) do
      {:ok, %{"list" => updated}}
    end
  end

  def build_change(%{depth: :map, value: data}, nil, %{key: key, value: value}) do
    with :ok <- valid_key_value(key, value),
         :ok <- valid_expand_map(data, key),
         do: {:ok, Map.put(data, key, value)}
  end

  def build_change(%{depth: :list} = data, id, %{at: at}) when not_empty_str(id) do
    with {:ok, list} <- get_list_from(data.value),
         {:ok, tuple} <- get_in_list(id, list) |> update_tuple(),
         {:ok, where} <- valid_at(id, at),
         {:ok, updated} <- update_at(where, tuple, list) do
      {:ok, %{"list" => updated}}
    end
  end

  def build_change(_, _, _), do: {:error, "Invalid data inputs"}

  # back into this so we don't have to rewrite update_at which requires a key/value
  # to be updated even if only moving position
  defp update_tuple(item) do
    [{key, value} | _] = Map.delete(item, "id") |> Map.to_list()
    {:ok, {item["id"], key, value}}
  end

  ##############################################################################
  # double-tap on a first-time create but ohwell, simpler code this way
  defp get_data(module, key, d_id, type) do
    attrs = [{key, d_id}, type: type]

    case module.one(attrs) do
      {:error, %{}} = e ->
        e

      {:error, :not_found} ->
        with {:ok, d} <- module.create(Map.new(attrs) |> Map.put(:value, %{})),
             do: module.enrich_depth(d)

      {:ok, d} ->
        module.enrich_depth(d)
    end
  end

  ##############################################################################
  def all_of_types(repo, module, key, data_id, types) when is_list(types) do
    from(d in module, where: field(d, ^key) == ^data_id and d.type in ^types)
    |> repo.all()
  end

  def get_by_type(repo, module, key, data_id, type) do
    from(d in module, where: field(d, ^key) == ^data_id and d.type == ^type)
    |> repo.all()
    |> case do
      [] -> :error
      [result] -> {:ok, result}
    end
  end
end
