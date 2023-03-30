defmodule Rivet.Ident.RoleMap.Lib do
  alias Rivet.Ident
  use Rivet.Ecto.Collection.Context, model: Ident.RoleMap

  # should probably be on Ident.Accesses
  def get_actions(%Ident.Access{role: %{id: role_id}, domain: domain, ref_id: ref_id}),
    do: get_actions(role_id, domain, ref_id)

  def get_actions(role_id, domain, ref_id) when is_integer(role_id) do
    key = [role_id, domain, ref_id]

    case Ident.Role.Cache.lookup(key) do
      [{_role_name, actions, _}] ->
        actions

      _no_cache ->
        actions = map_actions(key)
        Ident.Role.Cache.insert(key, actions, 300_000)
        actions
    end
  end

  def map_actions([role_id, domain, ref_id]) do
    Ident.RoleMap.all!(role_id: role_id)
    |> Enum.map(fn e -> [Ident.RoleMap.preload!(e, [:action]).action.name, domain, ref_id] end)
  end
end
