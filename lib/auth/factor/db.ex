defmodule Rivet.Data.Auth.Factor.Db do
  @type str :: String.t()
  @type log_msg :: str
  @type usr_msg :: str
  @type auth_result :: {:ok | :error, Auth.Domain.t()}
  alias Rivet.Data.Auth
  use Rivet.Ecto.Collection.Context
  require Logger
  import Rivet.Utils.Time, only: [epoch_time: 1]

  # override the function brought in by the collection module
  def one_with_user_tenant(factor_id) when is_binary(factor_id) do
    case Auth.Factor.Cache.get_user_factor(factor_id) do
      {:ok, %Auth.Factor{}} = pass ->
        pass

      :miss ->
        case @repo.one(
               from(f in Auth.Factor, where: f.id == ^factor_id, preload: [user: [:tenant]])
             ) do
          %Auth.Factor{user: %Auth.User{} = user} = factor ->
            user = Auth.User.Db.get_authz(user)
            user = %Auth.User{user | state: Map.put(user.state, :active_factor_id, factor.id)}

            %Auth.Factor{factor | user: user}
            |> Auth.Factor.Cache.persist()

          err ->
            err
        end
    end
  rescue
    err in Ecto.Query.CastError ->
      {:error, err.message}
  end

  @doc """
  Preload factors for a related model, with criteria, and only unexpired factors

      Auth.Factor.Db.preloaded_with(model, type)

  """
  def preloaded_with(model, type) when is_list(type) do
    now = epoch_time(:second)

    @repo.preload(model,
      factors:
        from(a in Auth.Factor,
          where: a.type in ^type and a.expires_at > ^now,
          order_by: [desc: :updated_at]
        )
    )
  end

  def preloaded_with(model, type) when is_atom(type) do
    now = epoch_time(:second)

    @repo.preload(model,
      factors:
        from(a in Auth.Factor,
          where: a.type == ^type and a.expires_at > ^now,
          order_by: [desc: :updated_at]
        )
    )
  end

  @doc """
  set a password

  Future change:

  change Auth.Factors so there is an archive state, some types when being cleaned
  are archived instead of deleted (such as passwords).

  Then AuthX.Signin.Local.load_password_factor should filter on !archived
  """
  @password_history 5
  def set_password(user, password, overrides \\ %{}) do
    Logger.info("setting password", user_id: user.id)
    {:ok, user} = Auth.User.preload(user, [:tenant])

    params =
      %{
        type: :password,
        expires_at: get_expiration(nil, :password),
        password: password,
        user_id: user.id,
        tenant_id: user.tenant.id
      }
      |> Map.merge(overrides)

    case Auth.Factor.create(params) do
      {:error, _} = pass ->
        pass

      {:ok, factor} ->
        clean_password_history(user.id, factor.id)
        {:ok, factor}
    end
  end

  def clean_password_history(user_id, excluding_id) do
    from(f in Auth.Factor,
      where: f.user_id == ^user_id and f.type == :password,
      order_by: [asc: f.expires_at]
    )
    |> @repo.all()
    |> Enum.filter(fn f -> f.id != excluding_id end)
    |> clean_old_factors(@password_history)
  end

  defp clean_old_factors([x | rest], max) do
    now = epoch_time(:second)

    cond do
      length(rest) + 1 > @password_history ->
        Auth.Factor.delete(x)

      x.expires_at > now ->
        Auth.Factor.update(x, %{expires_at: now})

      true ->
        :ok
    end

    clean_old_factors(rest, max)
  end

  defp clean_old_factors(_, _), do: :ok

  defp get_expiration(provider_exp, type) do
    cfg = Application.get_env(:authx, :auth_expire_limits)
    def_exp = 86400 * 365

    # because of how releases bring in configs, this appears as a keyword
    # list in prod, vs a map in lower environs.  grr.
    expiration =
      if is_list(cfg) do
        Keyword.get(cfg, type, def_exp)
      else
        if is_map(cfg),
          do: Map.get(cfg, type, def_exp),
          else: def_exp
      end

    case {provider_exp, epoch_time(:second) + expiration} do
      {nil, our_exp} ->
        our_exp

      {provider_exp, our_exp} when provider_exp >= our_exp ->
        our_exp

      {provider_exp, _our_exp} ->
        provider_exp
    end
  end

  # TODO: rename to set_federated_factor
  @spec set_factor(user :: Auth.User.t(), fedid :: Auth.Factor.FedId.t()) ::
          {:ok, Auth.Factor.t()} | {:error, Changeset.t()}
  def set_factor(user, fedid) do
    {:ok, user} = Auth.User.preload(user, [:tenant])

    Auth.Factor.create(%{
      name: fedid.provider.kid,
      type: :federated,
      fedtype: fedid.provider.type,
      expires_at: get_expiration(fedid.provider.exp, :password),
      user_id: user.id,
      tenant_id: user.tenant.id,
      details: Map.from_struct(fedid.provider)
    })
  end

  def drop_expired() do
    now = epoch_time(:second)

    # drop any non-password factors; password factors are cleaned when they
    # are changed (to keep a history)
    from(f in Auth.Factor,
      where: f.expires_at < ^now and f.type != :password
    )
    |> @repo.delete_all()
  end

  def all_not_expired!(%Auth.User{id: user_id}) do
    now = epoch_time(:second)

    from(f in Auth.Factor, where: f.user_id == ^user_id and f.expires_at > ^now)
    |> @repo.all()
  end

  def all_not_expired!(%Auth.User{} = user, type) when is_binary(type),
    do: all_not_expired!(user, Utils.Types.as_atom(type))

  def all_not_expired!(%Auth.User{id: user_id}, type) when is_atom(type) do
    now = epoch_time(:second)

    from(f in Auth.Factor,
      where: f.user_id == ^user_id and f.expires_at > ^now and f.type == ^type
    )
    |> @repo.all()
  end
end
