defmodule Rivet.Ident.User.Cache do
  @moduledoc """
  Used by websockets token authentication.  Very short term cache to efficiently
  load ~30 websockets all at once for a single dashboard.
  """
  use Rivet.Utils.LazyCache, bucket_key: :user_cache_bucket, keyset_key: :user_cache_keyset

  @persist_for 30_000

  alias Rivet.Ident

  def get_user(id) do
    case lookup(id) do
      [{_, user, _}] ->
        {:ok, user}

      _no_cache ->
        with {:ok, user} <- Ident.User.one(id: id) do
          Ident.User.Lib.get_authz(user) |> persist
        end
    end
  end

  def persist(%Ident.User{} = user) do
    insert(user.id, user, @persist_for)
    {:ok, user}
  end
end
