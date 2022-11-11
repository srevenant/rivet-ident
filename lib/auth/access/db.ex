defmodule Rivet.Data.Auth.Access.Db do
  use Unify.Ecto.Collection.Context

  @doc """
  Fold a list of accesses into a set of actions, using memory cache
  """
  @spec get_actions(Auth.User.t()) :: MapSet.t()
  def get_actions(%Auth.User{id: u_id}) do
    @repo.all(
      from(acc in Auth.Access,
        join: map in Auth.RoleMap,
        on: map.role_id == acc.role_id,
        join: act in Auth.Action,
        on: map.action_id == act.id,
        where: acc.user_id == ^u_id,
        select: {act.name, acc.domain, acc.ref_id}
        # distinct... only if :global and multiple roles with same action... a
        # future problem we can revisit when it arises -BJG
        # distinct: act.name
      )
    )
    |> MapSet.new()
  end

  @spec get_actions(Auth.User.t(), domain :: atom(), ref_id :: binary()) :: MapSet.t()
  def get_actions(%Auth.User{id: u_id}, domain, ref_id) do
    @repo.all(
      from(acc in Auth.Access,
        join: map in Auth.RoleMap,
        on: map.role_id == acc.role_id,
        join: act in Auth.Action,
        on: map.action_id == act.id,
        where: acc.user_id == ^u_id and acc.domain == ^domain and acc.ref_id == ^ref_id,
        select: {act.name, acc.domain, acc.ref_id},
        distinct: act.name
      )
    )
    |> MapSet.new()
  end

  # @spec get_subscriptions(accesses :: list()) :: MapSet.t()
  # def get_subscriptions(accesses) when is_list(accesses) do
  #   ## TODO: switch this to a joined SELECT - ecto-fu
  #   MapSet.new(
  #     Enum.reduce(accesses, [], fn access, acc ->
  #       case Auth.Access.preload(access, [:role]) do
  #         {:ok, %Auth.Access{role: %Auth.Role{subscription: true}}} ->
  #           acc ++ Auth.RoleMap.Db.get_actions(access.role_id)
  #
  #         {:ok, _} ->
  #           acc
  #       end
  #     end)
  #   )
  # end

  @spec add(Auth.User.t() | String.t(), atom(), String.t() | nil) ::
          {:ok, Auth.Access.t()} | {:error, String.t()}
  def add(user, role, ref_id \\ nil)

  def add(%Auth.User{} = user, role_atom, ref_id),
    do: add(user.id, role_atom, ref_id)

  def add(user_id, role_atom, ref_id) when is_atom(role_atom) and is_binary(user_id) do
    case Auth.Role.one(name: role_atom) do
      {:ok, role} ->
        Auth.Access.Db.upsert(%{
          role_id: role.id,
          user_id: user_id,
          domain: role.domain,
          ref_id: ref_id
        })

      _ ->
        {:error, "cannot find role #{inspect(role_atom)}"}
    end
  end

  @spec drop(Auth.User.t(), atom() | nil, String.t() | nil) ::
          {:ok, Auth.Access.t()} | {:error, String.t()}

  def drop(%Auth.User{} = user, role_atom, ref_id \\ nil) when is_atom(role_atom) do
    case Auth.Role.one(name: role_atom) do
      {:ok, role} ->
        case Auth.Access.one(
               role_id: role.id,
               user_id: user.id,
               domain: role.domain,
               ref_id: ref_id
             ) do
          {:ok, access} ->
            Auth.Access.delete(access)

          _ ->
            {:error, "cannot find access link"}
        end

      {:error, _} ->
        {:error, "cannot find role #{role_atom}"}
    end
  end

  def delete_by_user(user_id, domain, ref_id) do
    Auth.Access.delete_all(user_id: user_id, domain: domain, ref_id: ref_id)
    :ok
  end

  def delete_by_user(user_id) do
    {:ok, @repo.delete_all(from(a in Auth.Access, where: a.user_id == ^user_id))}
  end
end
