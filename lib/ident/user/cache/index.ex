defmodule Rivet.Ident.User.Cache do
  @moduledoc """
  Used by websockets token authentication.  Very short term cache to efficiently
  load ~30 websockets all at once for a single dashboard.
  """
  use Rivet.Utils.LazyCache

  @persist_for 30_000

  alias Rivet.Ident

  def get_user(id) do
    case lookup(id) do
      [{_, user, _}] ->
        {:ok, user}

      _no_cache ->
        # TODO: reconcile overlap of these two caches
        with {:ok, user} <- Ident.User.one(id: id),
             {:ok, user} <- Rivet.Auth.Cache.get_authz(user),
             do: persist(user)
    end
  end

  def persist(%Ident.User{} = user) do
    insert(user.id, user, @persist_for)
    {:ok, user}
  end
end
