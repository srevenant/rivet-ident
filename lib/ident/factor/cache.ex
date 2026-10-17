defmodule Rivet.Ident.Factor.Cache do
  use Rivet.Utils.LazyCache

  @persist_for 600_000

  use Rivet.Ident
  alias Ident.Factor
  import Ecto.Query

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

  def persist(%Factor{} = factor) do
    insert(factor.id, factor, @persist_for)
    {:ok, factor}
  end

  # used to update cache if user state changes
  def update_user(%User{state: %{active_factor_id: id}} = user) do
    with {:ok, factor} <- get_user_factor(id) do
      persist(%Factor{factor | user: user})
    end

    :ok
  end

  def update_user(_), do: :ok

  def invalidate_all_for(user_id) do
    from(f in Factor, where: f.user_id == ^user_id, select: f.id)
    |> Factor.all!()
    |> Enum.each(&delete/1)
  end
end
