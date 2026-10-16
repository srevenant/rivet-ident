defmodule Rivet.Auth.Cache do
  use Rivet.Utils.LazyCache
  use Rivet.Ident
  alias Rivet.Ident.Access

  @persist_for 60_000
  def get_authz(u, opts \\ [])

  def get_authz(%User{} = user, []) do
    case lookup(user.id) do
      [{_, authz, _}] -> {:ok, %User{user | authz}}
      _no_cache -> get_cache_actions(user, [])
    end
  end

  def get_authz(%User{} = user, force: true),
    do: get_cache_actions(user, force: true)

  defp get_cache_actions(%User{} = user, opts) do
    user = User.preload!(user, [:accesses], opts)
    authz = Access.Lib.get_actions(user)
    insert(user.id, authz, @persist_for)
    {:ok, %User{user | authz}}
  end
end
