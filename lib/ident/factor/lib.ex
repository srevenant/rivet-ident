defmodule Rivet.Ident.Factor.Lib do
  @type str :: String.t()
  @type log_msg :: str
  @type usr_msg :: str
  @type auth_result :: {:ok | :error, Rivet.Auth.Domain.t()}
  alias Rivet.Ident
  use Rivet.Ecto.Collection.Context, model: Ident.Factor
  require Logger
  import Rivet.Utils.Time, only: [epoch_time: 1]

  # override the function brought in by the collection module
  # was one_with_user_tenant
  def get(factor_id) when is_binary(factor_id) do
    case Ident.Factor.Cache.get_user_factor(factor_id) do
      {:ok, %Ident.Factor{}} = pass ->
        pass

      :miss ->
        case Ident.Factor.one!(
               from(f in Ident.Factor, where: f.id == ^factor_id, preload: [:user])
             ) do
          %Ident.Factor{user: %Ident.User{} = user} = factor ->
            user = Ident.User.Lib.get_authz(user)
            user = %Ident.User{user | state: Map.put(user.state, :active_factor_id, factor.id)}

            %Ident.Factor{factor | user: user}
            |> Ident.Factor.Cache.persist()

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

      Ident.Factor.Lib.preloaded_with(model, type)

  """
  def preloaded_with(%Ident.User{} = user, type) when is_list(type) do
    now = epoch_time(:second)

    Ident.User.preload!(user,
      factors:
        from(a in Ident.Factor,
          where: a.type in ^type and a.expires_at > ^now,
          order_by: [desc: :updated_at]
        )
    )
  end

  def preloaded_with(%Ident.User{} = user, type) when is_atom(type) do
    now = epoch_time(:second)

    Ident.User.preload!(user,
      factors:
        from(a in Ident.Factor,
          where: a.type == ^type and a.expires_at > ^now,
          order_by: [desc: :updated_at]
        )
    )
  end

  @doc """
  ```
  iex> strong_password("<KO)(IJM,ko09ijm")
  :ok
  iex> strong_password("boo")
  {:error, "Password is not long enough (greater than 8)"}
  iex> strong_password("<ko)(ijm,ko09ijm")
  {:error, "Password needs both upper and lower case characters"}
  iex> strong_password("KOIJMko09ijm")
  {:error, "Password needs special characters (not alphanumeric)"}
  iex> strong_password("<KO)(IJM,koijm")
  {:error, "Password needs numbers"}
  iex> strong_password("<)(,)(*&^%$#@><")
  {:error, "Password needs letters"}
  ```
  """
  @password_minlen 8
  def strong_password(password) do
    cond do
      String.length(password) < @password_minlen ->
        {:error, "Password is not long enough (greater than #{@password_minlen})"}

      Regex.replace(~r/[a-z]/i, password, "") == password ->
        {:error, "Password needs letters"}

      String.downcase(password) == password ->
        {:error, "Password needs both upper and lower case characters"}

      Regex.replace(~r/[^a-z0-9]/i, password, "") == password ->
        {:error, "Password needs special characters (not alphanumeric)"}

      Regex.replace(~r/[0-9]/, password, "") == password ->
        {:error, "Password needs numbers"}

      true ->
        :ok
    end
  end

  @doc """
  set a password

  Future change:

  change Ident.Factors so there is an archive state, some types when being cleaned
  are archived instead of deleted (such as passwords).

  Then Auth.Signin.Local.load_password_factor should filter on !archived
  """

  @password_history 5
  def set_password(user, password, overrides \\ %{}) do
    with :ok <- strong_password(password) do
      Logger.info("setting password", user_id: user.id)

      params =
        %{
          type: :password,
          expires_at: get_expiration(nil, :password),
          password: password,
          user_id: user.id
        }
        |> Map.merge(overrides)

      case Ident.Factor.create(params) do
        {:error, _} = pass ->
          pass

        {:ok, factor} ->
          clean_password_history(user.id, factor.id)
          {:ok, factor}
      end
    end
  end

  def clean_password_history(user_id, excluding_id) do
    from(f in Ident.Factor,
      where: f.user_id == ^user_id and f.type == :password,
      order_by: [asc: f.expires_at]
    )
    |> Ident.Factor.all!()
    |> Enum.filter(fn f -> f.id != excluding_id end)
    |> clean_old_factors(@password_history)
  end

  defp clean_old_factors([x | rest], max) do
    now = epoch_time(:second)

    cond do
      length(rest) + 1 > @password_history ->
        Ident.Factor.delete(x)

      x.expires_at > now ->
        Ident.Factor.update(x, %{expires_at: now})

      true ->
        :ok
    end

    clean_old_factors(rest, max)
  end

  defp clean_old_factors(_, _), do: :ok

  defp get_expiration(provider_exp, type) do
    cfg = Rivet.Auth.Settings.getcfg(:auth_expire_limits, %{})
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
  @spec set_factor(user :: Ident.User.t(), fedid :: Ident.Factor.FedId.t()) ::
          {:ok, Ident.Factor.t()} | {:error, Ecto.Changeset.t()}
  def set_factor(user, fedid) do
    Ident.Factor.create(%{
      name: fedid.provider.kid,
      type: :federated,
      fedtype: fedid.provider.type,
      expires_at: get_expiration(fedid.provider.exp, :password),
      user_id: user.id,
      details: Map.from_struct(fedid.provider)
    })
  end

  def get_user(factor_id) do
    case get(factor_id) do
      {:ok, %Ident.Factor{user: %Ident.User{}} = factor} ->
        {:ok, factor}

      {:error, _} ->
        {:error, "Cannot find identity factor=#{factor_id}"}
    end
  end

  def drop_expired() do
    now = epoch_time(:second)

    # drop any non-password factors; password factors are cleaned when they
    # are changed (to keep a history)
    from(f in Ident.Factor,
      where: f.expires_at < ^now and f.type != :password
    )
    |> Ident.Factor.delete_all()
  end

  def all_not_expired!(%Ident.User{id: user_id}) do
    now = epoch_time(:second)

    from(f in Ident.Factor, where: f.user_id == ^user_id and f.expires_at > ^now)
    |> Ident.Factor.all!()
  end

  def all_not_expired!(%Ident.User{} = user, type) when is_binary(type),
    do: all_not_expired!(user, Transmogrify.As.as_atom!(type))

  def all_not_expired!(%Ident.User{id: user_id}, type) when is_atom(type) do
    now = epoch_time(:second)

    from(f in Ident.Factor,
      where: f.user_id == ^user_id and f.expires_at > ^now and f.type == ^type
    )
    |> Ident.Factor.all!()
  end
end
