defmodule Rivet.Ident.Factor.Lib do
  @type str :: String.t()
  @type log_msg :: str
  @type usr_msg :: str
  @type auth_result :: {:ok | :error, Rivet.Auth.Domain.t()}

  use Rivet.Ident
  use Rivet.Ecto.Collection.Context, model: Ident.Factor
  require Logger
  import Rivet.Utils.Time, only: [epoch_time: 1]
  import Rivet.Guards
  import Rivet.Auth.Settings, only: [getcfg: 2]
  alias Ident.{Factor, User}

  ##############################################################################
  def get_user(factor_id) do
    case get(factor_id) do
      {:ok, %Factor{user: %User{}} = factor} ->
        {:ok, factor}

      {:error, _} ->
        {:error, "Cannot find identity factor=#{factor_id}"}
    end
  end

  # override the function brought in by the collection module
  # was one_with_user_tenant
  def get(factor_id) when is_binary(factor_id) do
    with :miss <- Factor.Cache.get_user_factor(factor_id),
         {:ok, %{user: %User{}} = f} <- Factor.one([id: factor_id], [:user]),
         {:ok, %User{} = user} = Rivet.Auth.Cache.get_authz(f.user) do
      user = %User{user | state: Map.put(user.state, :active_factor_id, f.id)}
      Factor.Cache.persist(%Factor{f | user})
    end
  rescue
    # coveralls-ignore-next-line
    err in Ecto.Query.CastError -> {:error, err.message}
  end

  ##############################################################################
  @doc """
  Preload factors for a related model, with criteria, and only unexpired factors

      Factor.Lib.preloaded_with(model, type)

  """
  def preloaded_with(%User{} = user, types) when is_list(types) do
    now = epoch_time(:second)

    User.preload!(user,
      factors:
        from(a in Factor,
          where: a.type in ^types and a.expires_at > ^now,
          order_by: [desc: :updated_at]
        )
    )
  end

  def preloaded_with(%User{} = user, type) when is_atom(type) do
    now = epoch_time(:second)

    User.preload!(user,
      factors:
        from(a in Factor,
          where: a.type == ^type and a.expires_at > ^now,
          order_by: [desc: :updated_at]
        )
    )
  end

  ##############################################################################
  @doc """
  set a password

  Future change:

  change Factors so there is an archive state, some types when being cleaned
  are archived instead of deleted (such as passwords).

  Then Auth.Signin.Local.load_password_factor should filter on !archived
  """
  def set_password(user, password, overrides \\ %{}) do
    with :ok <- Rivet.Auth.Password.strong_password(password) do
      params =
        %{
          type: :password,
          expires_at: get_expiration(nil, :password),
          password: password,
          user_id: user.id
        }
        |> Map.merge(overrides)

      @repo.transact(fn ->
        # Serialize password changes for this user
        query = from(u in User, where: u.id == ^user.id, lock: "FOR UPDATE")

        with {:ok, %User{}} <- User.one(query),
             {:ok, factor} <- Factor.create(params),
             :ok <- clean_password_history(user.id, factor.id) do
          {:ok, factor}
        end
      end)
    end
  end

  ##############################################################################
  def clean_password_history(user_id, excluding_id) do
    from(f in Factor,
      where: f.user_id == ^user_id and f.type == :password,
      order_by: [asc: f.inserted_at, asc: f.id]
    )
    |> Factor.all!()
    |> Enum.reject(&(&1.id == excluding_id))
    |> clean_old_factors(getcfg(:password_history, 5) - 1)
  end

  ####
  defp clean_old_factors([factor | rest], max) do
    with {:ok, _} <- clean_old_update_factor(factor, length(rest), max),
         do: clean_old_factors(rest, max)
  end

  defp clean_old_factors([], _), do: :ok

  ####
  defp clean_old_update_factor(f, remaining, max) do
    now = epoch_time(:second)

    cond do
      remaining >= max -> Factor.delete(f)
      f.expires_at > now -> Factor.update(f, %{expires_at: now})
      true -> {:ok, f}
    end
  end

  ##############################################################################
  # default 1 year
  @default_expire 86400 * 365

  defp default_expiration(type) do
    getcfg(:auth_expire_limits, %{})
    |> Map.new()
    |> Map.get(type, @default_expire)
    |> Kernel.+(epoch_time(:second))
  end

  def get_expiration(nil, type), do: default_expiration(type)

  def get_expiration(provider_exp, type) do
    def_exp = default_expiration(type)

    if provider_exp >= def_exp do
      def_exp
    else
      provider_exp
    end
  end

  ### deprecated? Now we really just use ExtIdent, and this is largely ignored?
  ### or is FedId still a thing...
  # @spec set_federated_factor(user :: User.t(), fedid :: Factor.FedId.t()) ::
  #         {:ok, Factor.t()} | {:error, Ecto.Changeset.t()}
  # def set_federated_factor(user, fedid) do
  #   Factor.create(%{
  #     name: fedid.provider.kid,
  #     type: :federated,
  #     fedtype: fedid.provider.type,
  #     expires_at: get_expiration(fedid.provider.exp, :password),
  #     user_id: user.id,
  #     details: Map.from_struct(fedid.provider)
  #   })
  # end

  def drop_expired() do
    now = epoch_time(:second)

    # drop any non-password factors; password factors are cleaned when they
    # are changed (to keep a history)
    from(f in Factor, where: f.expires_at < ^now and f.type != :password)
    |> Factor.delete_all()
  end

  def all_not_expired!(%User{id: user_id}) do
    now = epoch_time(:second)

    from(f in Factor, where: f.user_id == ^user_id and f.expires_at > ^now)
    |> Factor.all!()
  end

  def all_not_expired!(%User{} = user, type) when is_binary(type),
    do: all_not_expired!(user, Transmogrify.As.as_atom!(type))

  def all_not_expired!(%User{id: user_id}, type) when is_atom(type) do
    now = epoch_time(:second)

    from(f in Factor,
      where: f.user_id == ^user_id and f.expires_at > ^now and f.type == ^type
    )
    |> Factor.all!()
  end
end
