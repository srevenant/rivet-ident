defmodule Rivet.Ident.Access.Lib do
  alias Rivet.Ident.{Access, Role, Action}
  use Rivet.Ecto.Collection.Context, model: Access
  use Rivet.Ident

  @doc """
  Fold a list of accesses into a set of actions, using memory cache
  """
  @spec get_actions(User.t()) :: MapSet.t()
  def get_actions(%User{id: u_id}) do
    from(acc in Access,
      join: map in Role.Map,
      on: map.role_id == acc.role_id,
      join: act in Action,
      on: map.action_id == act.id,
      where: acc.user_id == ^u_id,
      select: {act.name, acc.domain, acc.ref_id}
      # distinct... only if :global and multiple roles with same action... a
      # future problem we can revisit when it arises -BJG
      # distinct: act.name
    )
    |> Access.all!()
    |> MapSet.new()
  end

  @spec get_actions(User.t(), domain :: atom(), ref_id :: binary()) :: MapSet.t()
  def get_actions(%User{id: u_id}, domain, ref_id) do
    from(acc in Access,
      join: map in Role.Map,
      on: map.role_id == acc.role_id,
      join: act in Action,
      on: map.action_id == act.id,
      where: acc.user_id == ^u_id and acc.domain == ^domain and acc.ref_id == ^ref_id,
      select: {act.name, acc.domain, acc.ref_id},
      distinct: act.name
    )
    |> Access.all!()
    |> MapSet.new()
  end

  def action_strings!(user, domain, id) when is_uuid(id) do
    get_actions(user, domain, id)
    |> Enum.map(fn {a, _, _} -> Atom.to_string(a) end)
  end

  ##############################################################################
  defguard is_role_key(role_key) when is_atom(role_key) or is_integer(role_key)

  def valid_user_id(%User{id}), do: {:ok, id}
  def valid_user_id(id) when is_uuid(id), do: {:ok, id}
  def valid_user_id(_), do: {:error, "Invalid user or user id"}

  ##############################################################################
  @spec add(User.t() | String.t(), atom() | integer(), String.t() | nil) ::
          {:ok, Access.t()} | {:error, String.t()}
  def add(user, role_key, ref_id \\ nil) when is_role_key(role_key) do
    with {:ok, user_id} <- valid_user_id(user) do
      case get_role(role_key) do
        # giving it a ref_id of nil forces it :global
        {:ok, %{id: role_id}} when is_nil(ref_id) -> add_(%{role_id, user_id, domain: :global})
        {:ok, %{domain, id: role_id}} -> add_(%{role_id, user_id, domain, ref_id})
        _ -> {:error, "Cannot find role=#{role_key}"}
      end
    end
  end

  # # # # # # #
  defp add_(%{user_id} = attrs) do
    with {:ok, _} = r <- Access.upsert(attrs), do: clear_auth_cache(user_id, r)
  end

  ##############################################################################
  @spec drop(User.t(), atom() | nil, String.t() | nil) ::
          {:ok, deleted_count :: integer()} | {:error, String.t()}

  def drop(user, role_key, ref_id \\ nil) when is_role_key(role_key) do
    with {:ok, user_id} <- valid_user_id(user) do
      case get_role(role_key) do
        {:ok, %{id: role_id}} when is_nil(ref_id) ->
          delete_access(user_id, role_id, :global)

        {:ok, %{domain, id: role_id}} ->
          with {:ok, c1} <- delete_access(user_id, role_id, :global),
               {:ok, c2} <- delete_access(user_id, role_id, domain, ref_id),
               do: {:ok, c1 + c2}

        {:error, _} ->
          {:error, "cannot find role=#{role_key}"}
      end
    end
  end

  # # # # # # # # #
  def delete_access(user_id, role_id, domain, ref_id \\ nil)

  def delete_access(user_id, role_id, :global, nil),
    do: delete_all(user_id, role_id: role_id, domain: :global)

  def delete_access(user_id, role_id, domain, ref_id) when is_uuid(ref_id),
    do: delete_all(user_id, role_id: role_id, domain: domain, ref_id: ref_id)

  # # # # # # # #
  def delete_all(user_id, and_more \\ []) when is_list(and_more) do
    with {x, _} <- Access.delete_all([user_id: user_id] ++ and_more),
         do: clear_auth_cache(user_id, {:ok, x})
  end

  ##############################################################################
  defp get_role(role_id) when is_integer(role_id), do: Ident.Role.one(id: role_id)
  defp get_role(role_name) when is_atom(role_name), do: Ident.Role.one(name: role_name)

  ##############################################################################
  @doc """

  change/4 is a helper to simplify front-end API calls

  """
  def change(action, key, user, ref_id) when is_role_key(key) do
    with {:ok, user_id} <- valid_user_id(user), do: change_(action, key, user_id, ref_id)
  end

  # # # # # # # #
  defp change_(:upsert, role_key, user_id, ref_id) do
    with {:ok, _} = r <- add(user_id, role_key, ref_id), do: clear_auth_cache(user_id, r)
  end

  defp change_(:remove, role_key, user_id, ref_id) do
    with {:ok, _} = r <- drop(user_id, role_key, ref_id), do: clear_auth_cache(user_id, r)
  end

  ##############################################################################
  defp clear_auth_cache(user_id, return) do
    Rivet.Auth.Cache.delete(user_id)
    return
  end
end
