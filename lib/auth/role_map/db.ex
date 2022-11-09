defmodule Cato.Data.Auth.RoleMaps do
  alias Cato.Data.Auth
  use Unify.Ecto.Collection.Context

  # should probably be on Auth.Accesses
  def get_actions(%Auth.Access{role: %{id: role_id}, domain: domain, ref_id: ref_id}),
    do: get_actions(role_id, domain, ref_id)

  def get_actions(role_id, domain, ref_id) when is_integer(role_id) do
    key = [role_id, domain, ref_id]

    case Auth.Role.Cache.lookup(key) do
      [{_role_name, actions, _}] ->
        actions

      _no_cache ->
        actions = map_actions(key)
        Auth.Role.Cache.insert(key, actions, 300_000)
        actions
    end
  end

  def map_actions([role_id, domain, ref_id]) do
    Auth.RoleMap.all!(role_id: role_id)
    |> @repo.preload(:action)
    |> Enum.map(fn e -> [e.action.name, domain, ref_id] end)
  end
end
