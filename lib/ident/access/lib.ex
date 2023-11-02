defmodule Rivet.Ident.Access.Lib do
  alias Rivet.Ident
  use Rivet.Ecto.Collection.Context, model: Ident.Access

  @doc """
  Fold a list of accesses into a set of actions, using memory cache
  """
  @spec get_actions(Ident.User.t()) :: MapSet.t()
  def get_actions(%Ident.User{id: u_id}) do
    Ident.Access.all!(
      from(acc in Ident.Access,
        join: map in Ident.RoleMap,
        on: map.role_id == acc.role_id,
        join: act in Ident.Action,
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

  @spec get_actions(Ident.User.t(), domain :: atom(), ref_id :: binary()) :: MapSet.t()
  def get_actions(%Ident.User{id: u_id}, domain, ref_id) do
    Ident.Access.all!(
      from(acc in Ident.Access,
        join: map in Ident.RoleMap,
        on: map.role_id == acc.role_id,
        join: act in Ident.Action,
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
  #       case Ident.Access.preload(access, [:role]) do
  #         {:ok, %Ident.Access{role: %Ident.Role{subscription: true}}} ->
  #           acc ++ Ident.RoleMap.Lib.get_actions(access.role_id)
  #
  #         {:ok, _} ->
  #           acc
  #       end
  #     end)
  #   )
  # end

  @spec add(Ident.User.t() | String.t(), atom(), String.t() | nil) ::
          {:ok, Ident.Access.t()} | {:error, String.t()}
  def add(user, role, domain \\ :global, ref_id \\ nil)

  def add(%Ident.User{} = user, role, domain, ref_id),
    do: add(user.id, role, domain, ref_id)

  def add(user_id, role, domain, ref_id) when is_atom(role) and is_binary(user_id) and is_atom(domain) do
    case Ident.Role.one(name: role) do
      {:ok, role} ->
        Ident.Access.upsert(%{
          role_id: role.id,
          user_id: user_id,
          domain: domain,
          ref_id: ref_id
        })

      _ ->
        {:error, "cannot find role #{inspect(role)}"}
    end
  end

  @spec drop(Ident.User.t(), atom() | nil, String.t() | nil) ::
          {:ok, Ident.Access.t()} | {:error, String.t()}

  def drop(%Ident.User{} = user, role_atom, ref_id \\ nil) when is_atom(role_atom) do
    case Ident.Role.one(name: role_atom) do
      {:ok, role} ->
        case Ident.Access.one(
               role_id: role.id,
               user_id: user.id,
               domain: role.domain,
               ref_id: ref_id
             ) do
          {:ok, access} ->
            Ident.Access.delete(access)

          _ ->
            {:error, "cannot find access link"}
        end

      {:error, _} ->
        {:error, "cannot find role #{role_atom}"}
    end
  end

  def delete_by_user(user_id, domain, ref_id),
    do: Ident.Access.delete_all(user_id: user_id, domain: domain, ref_id: ref_id)

  def delete_by_user(user_id),
    do: Ident.Access.delete_all(from(a in Ident.Access, where: a.user_id == ^user_id))
end
