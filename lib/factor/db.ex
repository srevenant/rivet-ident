defmodule Cato.Data.Auth.Factor.Db do
  @type str :: String.t()
  @type log_msg :: str
  @type usr_msg :: str
  @type auth_result :: {:ok | :error, Auth.AuthDomain.t()}
  alias Cato.Data.Auth
  use Unify.Ecto.Collection.Context

  # override the function brought in by the collection module
  def one_with_user_tenant(factor_id) when is_binary(factor_id) do
    case Auth.Factor.Cache.get_user_factor(factor_id) do
      {:ok, %Auth.Factor{}} = pass ->
        pass

      :miss ->
        case Repo.one(
               from(f in Auth.Factor, where: f.id == ^factor_id, preload: [user: [:tenant]])
             ) do
          %Auth.Factor{user: %Auth.User{} = user} = factor ->
            user = Auth.Users.get_authz(user)
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

      Auth.Factors.preloaded_with(model, type)

  """
  def preloaded_with(model, type) when is_list(type) do
    now = Utils.Time.epoch_time(:second)

    Repo.preload(model,
      factors:
        from(a in Auth.Factor,
          where: a.type in ^type and a.expires_at > ^now,
          order_by: [desc: :updated_at]
        )
    )
  end

  def preloaded_with(model, type) when is_atom(type) do
    now = Utils.Time.epoch_time(:second)

    Repo.preload(model,
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
    {:ok, user} = Auth.Users.preload(user, [:tenant])

    params =
      %{
        type: :password,
        expires_at: get_expiration(nil, :password),
        password: password,
        user_id: user.id,
        tenant_id: user.tenant.id
      }
      |> Map.merge(overrides)

    case Auth.Factors.create(params) do
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
    |> Repo.all()
    |> Enum.filter(fn f -> f.id != excluding_id end)
    |> clean_old_factors(@password_history)
  end

  defp clean_old_factors([x | rest], max) do
    now = Utils.Time.epoch_time(:second)

    cond do
      length(rest) + 1 > @password_history ->
        Auth.Factors.delete(x)

      x.expires_at > now ->
        Auth.Factors.update(x, %{expires_at: now})

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

    case {provider_exp, Utils.Time.epoch_time(:second) + expiration} do
      {nil, our_exp} ->
        our_exp

      {provider_exp, our_exp} when provider_exp >= our_exp ->
        our_exp

      {provider_exp, _our_exp} ->
        provider_exp
    end
  end

  # TODO: rename to set_federated_factor
  @spec set_factor(user :: Auth.User.t(), fedid :: Auth.AuthFedId.t()) ::
          {:ok, Auth.Factor.t()} | {:error, Changeset.t()}
  def set_factor(user, fedid) do
    {:ok, user} = Auth.Users.preload(user, [:tenant])

    Auth.Factors.create(%{
      name: fedid.provider.kid,
      type: :federated,
      fedtype: fedid.provider.type,
      expires_at: get_expiration(fedid.provider.exp, :password),
      user_id: user.id,
      tenant_id: user.tenant.id,
      details: Map.from_struct(fedid.provider)
    })
  end

  def get_user_with_tenant(factor_id, tenant = %Auth.Tenant{}) do
    # load the factor and user, matching current tenant
    tenant_code = tenant.code

    case Auth.Factors.one_with_user_tenant(factor_id) do
      nil ->
        {:error, "Invalid tenant"}

      {:ok, %Auth.Factor{user: %Auth.User{tenant: %Auth.Tenant{code: ^tenant_code}}} = factor} ->
        {:ok, factor}

      {:ok, %Auth.Factor{}} ->
        {:error, "Factor in wrong tenant?"}

      {:error, _} ->
        {:error, "Cannot find identity factor=#{factor_id}"}
    end
  end

  def drop_expired() do
    now = Utils.Time.epoch_time(:second)

    # drop any non-password factors; password factors are cleaned when they
    # are changed (to keep a history)
    from(f in Auth.Factor,
      where: f.expires_at < ^now and f.type != :password
    )
    |> Repo.delete_all()
  end

  def all_not_expired!(%Auth.User{id: user_id}) do
    now = Utils.Time.epoch_time(:second)

    from(f in Auth.Factor, where: f.user_id == ^user_id and f.expires_at > ^now)
    |> Repo.all()
  end

  def all_not_expired!(%Auth.User{} = user, type) when is_binary(type),
    do: all_not_expired!(user, Utils.Types.to_atom(type))

  def all_not_expired!(%Auth.User{id: user_id}, type) when is_atom(type) do
    now = Utils.Time.epoch_time(:second)

    from(f in Auth.Factor,
      where: f.user_id == ^user_id and f.expires_at > ^now and f.type == ^type
    )
    |> Repo.all()
  end
end
