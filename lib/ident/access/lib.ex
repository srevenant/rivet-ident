defmodule Rivet.Ident.Access.Lib do
  alias Rivet.Ident.{Access, Role}
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
  @spec add(User.t() | String.t(), atom(), String.t() | nil) ::
          {:ok, Access.t()} | {:error, String.t()}
  def add(user, role, ref_id \\ nil)

  def add(%User{} = user, role, ref_id), do: add(user.id, role, ref_id)

  def add(user_id, role, ref_id) when is_uuid(user_id) and is_atom(role) do
    case Role.one(name: role) do
      {:ok, %{domain, id: role_id}} ->
        # ref_id might be nil, which throws off the Access.one
        attrs = no_nils(%{role_id, user_id, domain, ref_id})

        with {:error, :not_found} <- Access.one(Map.to_list(attrs)),
             {:ok, _} = ok <- Access.create(attrs) do
          Rivet.Auth.Cache.delete(user_id)
          ok
        end

      _ ->
        {:error, "cannot find role #{inspect(role)}"}
    end
  end

  defp no_nils(map), do: Transmogrify.transmogrify(map, no_nil_value: true)

  ##############################################################################
  @spec drop(User.t(), atom() | nil, String.t() | nil) ::
          {:ok, Access.t()} | {:error, String.t()}

  def drop(%User{id: user_id}, role_atom, ref_id \\ nil) when is_atom(role_atom) do
    case Role.one(name: role_atom) do
      {:ok, %{domain, id: role_id}} ->
        attrs = no_nils(%{role_id, user_id, domain, ref_id}) |> Map.to_list()

        case Access.one(attrs) do
          {:ok, access} -> delete_all(access)
          _ -> {:error, "cannot find access link"}
        end

      {:error, _} ->
        {:error, "cannot find role #{role_atom}"}
    end
  end

  ##############################################################################
  # /3
  def delete_all(user_id, domain, ref_id),
    do: delete_all_(user_id, domain: domain, ref_id: ref_id)

  # /1
  def delete_all(user_id) when is_uuid(user_id),
    do: delete_all_(user_id, [])

  # TBD if needed
  # def delete_all(%Access{user_id, domain, ref_id: nil}),
  #   do: delete_all_(user_id, domain: domain)
  #
  # def delete_all(%Access{user_id, domain, ref_id}),
  #   do: delete_all_(user_id, domain: domain, ref_id: ref_id)

  defp delete_all_(user_id, and_more) when is_list(and_more) do
    with {x, _} <- Access.delete_all([user_id: user_id] ++ and_more) do
      Rivet.Auth.Cache.delete(user_id)
      {:ok, x}
    end
  end

  ##############################################################################
  def delete_user_domain(user_id, domain, ref_id),
    do: Access.delete_all(user_id: user_id, domain: domain, ref_id: ref_id)

  def delete_user_access(user_id),
    do: Access.delete_all(from(a in Access, where: a.user_id == ^user_id))
end
