defmodule Rivet.Ident.Factor.Cache do
  use Rivet.Utils.LazyCache,
    bucket_key: :user_factor_cache_bucket,
    keyset_key: :user_factor_cache_keyset

  @persist_for 600_000

  alias Rivet.Ident

  @doc """
  Read-through cache for loading user factors from Ident.
  """
  def get_user_factor(id) do
    case lookup(id) do
      [{_, factor, _}] ->
        {:ok, factor}

      _no_cache ->
        :miss
    end
  end

  def persist(%Ident.Factor{} = factor) do
    insert(factor.id, factor, @persist_for)
    {:ok, factor}
  end

  # used to update cache if user state changes
  def update_user(%Ident.User{state: %{active_factor_id: id}} = user) do
    with {:ok, factor} <- get_user_factor(id) do
      persist(%Ident.Factor{factor | user: user})
    end

    :ok
  end

  def update_user(_), do: :ok
end
