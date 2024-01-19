defmodule Rivet.Ident.User.Lib do
  alias Rivet.Ident
  use Rivet.Ecto.Collection.Context, model: Ident.User
  alias Rivet.Auth
  require Logger

  def search(%{matching: match}, args) do
    match = "%#{String.downcase(Regex.replace(~r/[^a-z0-9]/i, match, ""))}%"

    from(u in Ident.User,
      join: e in Ident.Email,
      on: e.user_id == u.id,
      join: h in Ident.Handle,
      on: h.user_id == u.id,
      where: like(u.name, ^match) or like(h.handle, ^match) or like(e.address, ^match)
    )
    |> Rivet.Ecto.Collection.enrich_query_args(args)
    |> Rivet.Ident.User.all()
  end

  @doc """
  Bring in the list of authorized actions onto the user object (into :authz)

  Only load once, if authz is nil
  """
  @spec get_authz(user :: Ident.User.t()) :: Ident.User.t()
  def get_authz(%Ident.User{authz: authz} = user) when is_nil(authz) do
    {:ok, user} = Ident.User.preload(user, [:accesses])
    %Ident.User{user | authz: Rivet.Ident.Access.Lib.get_actions(user)}
  end

  def get_authz(%Ident.User{} = user), do: user

  @spec check_authz(user :: Ident.User.t(), Auth.Assertion.t()) ::
          {:ok | :error, Ident.User.t()}
  def check_authz(user, %Auth.Assertion{} = assertion) do
    key = {assertion.action, assertion.domain, assertion.ref_id}
    user = Ident.User.Lib.get_authz(user)

    if MapSet.member?(user.authz, key) do
      {:ok, user}
    else
      if assertion.fallback and MapSet.member?(user.authz, {assertion.action, :global, nil}) do
        {:ok, user}
      else
        {:error, user}
      end
    end
  end

  ##############################################################################
  # only periodically update last seen, to avoid severe performance hit
  @update_min_seconds 60
  def user_seen(%Ident.User{} = user) do
    now = Timex.now()

    if is_nil(user.last_seen) or Timex.diff(now, user.last_seen, :seconds) > @update_min_seconds do
      with {:ok, user} <- Ident.User.update(user, %{last_seen: now}) do
        Ident.Factor.Cache.update_user(user)
        user
      else
        err ->
          IO.inspect(err, label: "Error updating user.last_seen")
          user
      end
    else
      user
    end
  end

  def search_name!(pattern),
    do: Ident.User.all!(from(u in Ident.User, where: like(u.name, ^pattern)))

  ##############################################################################
  @doc """
  Helper function which accepts either user_id or user, and calls the passed
  function with the user model loaded including any preloads.  Send preloads
  as [] if none are desired.
  """
  def with_user(%Ident.User{} = user, preloads, func) do
    with {:ok, user} <- Ident.User.preload(user, preloads) do
      func.(user)
    end
  end

  def with_user(user_id, preloads, func) when is_binary(user_id) do
    case Ident.User.one(user_id, preloads) do
      {:error, _} = pass ->
        pass

      {:ok, %Ident.User{} = user} ->
        func.(user)
    end
  end

  # ##############################################################################
  # def send_password_reset(%Ident.User{} = user, %Ident.Email{} = email, %Ident.UserCode{} = code) do
  #   # let all emails on the account know
  #   with {:ok, user} <- Ident.User.preload(user, [:emails]) do
  #     sendmail(user.emails, &templates.password_reset/2, [email, code])
  #   end
  # end
  #
  # ##############################################################################
  # def send_failed_change(%Ident.Email{} = email, message) do
  #   sendmail(email, &templates.failed_change/2, message)
  # end
  #
  # ##############################################################################
  # def send_password_changed(%Ident.User{} = user) do
  #   with {:ok, user} <- Ident.User.preload(user, [:emails]) do
  #     sendmail(user.emails, &templates.password_changed/2)
  #   end
  # end

  ##############################################################################
  def all_since(time), do: Ident.User.all!(from(u in Ident.User, where: u.last_seen > ^time))

  ##############################################################################
  def add_email(user, eaddr, verified \\ false) do
    eaddr = String.trim(eaddr)

    # basic
    case Ident.Email.one(address: eaddr) do
      {:ok, %Ident.Email{} = email} ->
        Logger.warning("failed adding email", user_id: user.id, eaddr: eaddr)
        Rivet.Ident.cfg(:notify_user_failed_change).sendto(email, "add email to your account.")

        {:error, "That email already is associated with a different account"}

      {:error, _} ->
        has_email? = not Ident.Email.exists?(user_id: user.id)

        # add it
        case Ident.Email.create(%{
               user_id: user.id,
               verified: verified,
               primary: not has_email?,
               address: eaddr
             }) do
          {:ok, %Ident.Email{} = email} ->
            email = %Ident.Email{email | user: user}
            Rivet.Ident.cfg(:notify_user_verification).sendto(email)

            {:ok, email}

          {:error, chgset} ->
            {:error, Rivet.Utils.Ecto.Errors.convert_error_changeset(chgset)}
        end
    end
  end

  def check_user_status({:ok, %Auth.Domain{user: %Ident.User{type: :disabled}}}),
    do: {:error, %Auth.Domain{error: "sorry, account is disabled"}}

  def check_user_status(%Ident.User{type: :disabled}) do
    {:error, %Auth.Domain{error: "sorry, account is disabled"}}
  end

  def check_user_status(%Ident.User{} = user), do: {:ok, user}

  def check_user_status(pass) do
    pass
  end

  ##############################################################################
  def add_phone(user, phone) do
    # TODO: do an internal ph# validation
    phone = String.trim(phone)

    case Ident.Phone.one(user_id: user.id, number: phone) do
      {:ok, %Ident.Phone{} = phone} ->
        {:ok, phone}

      {:error, _} ->
        # add it
        case Ident.Phone.create(%{
               user_id: user.id,
               number: phone
             }) do
          {:ok, %Ident.Phone{} = phone} ->
            # TODO santity checks:
            # - pick primary
            # Logger.info("added phone", user_id: user.id, phone: phone)
            {:ok, phone}

          {:error, chgset} ->
            {:error, Rivet.Utils.Ecto.Errors.convert_error_changeset(chgset)}
        end
    end
  end

  ##############################################################################
  @spec has_other_admin?(Ident.Role.t(), Ident.User.t()) :: boolean() | {:error, String.t()}
  def has_other_admin?(%Ident.Role{name: :system_admin, id: r_id}, %Ident.User{id: user_id}) do
    query = from(a in Ident.Access, where: a.role_id == ^r_id and a.user_id != ^user_id)

    if Ident.User.aggregate(query, :count) > 0 do
      true
    else
      {:error, "Cannot remove last system_admin"}
    end
  end

  def has_other_admin?(_, _), do: true

  ##############################################################################
  @doc """
  iex> get_user("asdf")
  {:error, :not_found}

  iex> get_user("A73DD874-A724-494F-B9E2-2042A4383144")
  {:error, :not_found}

  iex> handle = insert(:ident_handle)
  ...> {:ok, u} = get_user(handle.user_id)
  ...> u.id
  handle.user_id

  iex> handle = insert(:ident_handle)
  ...> {:ok, u} = get_user(handle.handle, [:handle])
  ...> u.id
  handle.user_id

  """
  def get_user(id, preload \\ [])

  def get_user(id, preload) when is_binary(id) and byte_size(id) == 36 do
    with {:error, _} <- Ident.User.one([id: id], preload) do
      get_user_by_handle(id, preload)
    end
  end

  def get_user(id, preload), do: get_user_by_handle(id, preload)

  def get_user_by_handle(id, preload \\ []) do
    case Ident.Handle.one([handle: id], user: preload) do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, _} -> {:error, :not_found}
    end
  end
end
