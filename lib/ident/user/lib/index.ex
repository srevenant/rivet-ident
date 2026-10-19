defmodule Rivet.Ident.User.Lib do
  use Rivet.Ident
  use Rivet.Ecto.Collection.Context, model: User
  alias Rivet.Auth
  require Logger

  ##############################################################################
  # only periodically update last seen, to avoid severe performance hit
  @update_min_seconds 60
  def user_seen(%User{} = user, _opts \\ []) do
    now = DateTime.utc_now()

    if is_nil(user.last_seen) or DateTime.diff(now, user.last_seen, :second) > @update_min_seconds do
      case User.update(user, %{last_seen: now}) do
        {:ok, user} ->
          Rivet.Ident.Factor.Cache.update_user(user)
          user

        {:error, err} ->
          # coveralls-ignore-start
          Logger.error("Error updating user.last_seen", error: err)
          user
          # coveralls-ignore-stop
      end
    else
      user
    end
  end

  def search_name!(pattern),
    do: User.all!(from(u in User, where: like(u.name, ^pattern)))

  ##############################################################################
  @doc """
  Helper function which accepts either user_id or user, and calls the passed
  function with the user model loaded including any preloads.  Send preloads
  as [] if none are desired.
  """
  def with_user(%User{} = user, preloads, func) do
    with {:ok, user} <- User.preload(user, preloads) do
      func.(user)
    end
  end

  def with_user(user_id, preloads, func) when is_binary(user_id) do
    case User.one(user_id, preloads) do
      {:error, _} = pass ->
        pass

      {:ok, %User{} = user} ->
        func.(user)
    end
  end

  ##############################################################################
  def all_since(time), do: User.all!(from(u in User, where: u.last_seen > ^time))

  ##############################################################################
  def add_email(user, address, opts \\ %{}) do
    address = Email.Lib.clean_email(address)

    # basic
    case Email.one([address: address], [:user]) do
      {:ok, %Email{user_id} = email} ->
        if user_id != user.id do
          Logger.warning("Cannot add existing email to different user",
            user_id: user.id,
            address: address
          )

          Rivet.Ident.mailer_template(:user_failed_change).queue(
            email,
            "add email #{address} to a different account"
          )

          {:error, "Sorry, that email address is associated with a different account."}
        else
          {:ok, email}
        end

      {:error, :not_found} ->
        has_email? = Email.exists?(user_id: user.id)
        opts = Map.new(opts)

        attrs = %{
          address,
          user_id: user.id,
          verified: Map.get(opts, :verified, false),
          primary: not has_email?
        }

        # fix error shape
        with {:error, chgset} <- Email.create(attrs),
             do: {:error, Rivet.Ecto.Errors.convert_error_changeset(chgset)}
    end
  end

  def send_verify_email(u) do
    with {:error, e} <- send_verify_email_(User.preload!(u, [:emails])),
         # coveralls-ignore-next-line
         do: Rivet.Ident.critical_report(e)
  end

  def send_verify_email_(%User{id, emails: [%Email{address} = email | _]}) do
    Logger.info("verify email", user_id: id, eaddr: address)
    Rivet.Ident.mailer_template(:user_verification).queue(email)
  end

  def send_verify_email_(_), do: {:error, "Cannot email verify because user has no email address"}

  ##############################################################################
  @spec check_user_status(User.t() | Auth.Domain.t()) ::
          {:ok, User.t() | Auth.Domain.t()} | {:error, Auth.Domain.t()}
  def check_user_status(%User{type: :disabled}),
    do:
      {:error,
       %Auth.Domain{
         log: "Google signin failed: Attempted login on disabled account",
         error: "Sorry, account is disabled"
       }}

  def check_user_status(%User{} = user), do: {:ok, user}

  def check_user_status(%Auth.Domain{user: %User{} = user}), do: check_user_status(user)
  def check_user_status(_), do: {:error, "No user to verify"}

  ##############################################################################
  def add_phone(user, phone) do
    # TODO: do an internal ph# validation
    phone = String.trim(phone)

    with {:error, :not_found} <- Ident.Phone.one(user_id: user.id, number: phone),
         {:error, chgset} <- Ident.Phone.create(%{user_id: user.id, number: phone}),
         do: {:error, Rivet.Ecto.Errors.convert_error_changeset(chgset)}
  end

  ##############################################################################
  def delete_each([nil | rest], mod), do: delete_each(rest, mod)

  def delete_each([x | rest], mod) do
    with {:ok, _} <- mod.delete(x), do: delete_each(rest, mod)
  end

  def delete_each([], _), do: :ok

  @doc """

  We don't actually delete the base account, so we have to do the related things
  by hand. Instead we sanitize ONLY PII/personal information.

  iex> u = insert(:ident_user)
  iex> {:ok, _} = delete_account(u)

  """
  @preloads [:emails, :factors, :handle, :ext_ids, :phones]
  def delete_account(%User{} = u) do
    @repo.transact(fn ->
      with {:ok, u} <- User.preload(u, @preloads),
           {:ok, u} <- User.update(u, %{name: "DELETED", type: :disabled}),
           :ok <- delete_each(u.emails, Email),
           # :ok <- delete_each(u.mailer_subs, Rivet.Mailer.Subs),
           :ok <- delete_each([u.handle], Ident.Handle),
           :ok <- delete_each(u.phones, Ident.Phone),
           :ok <- delete_each(u.factors, Ident.Factor) do
        # possibly add:
        #  data (private info?)
        #  accesses/roles?
        #  settings?
        # last_seen: NO, keep
        # different primary key
        u_id = u.id

        Enum.each(u.ext_ids, fn %{origin: o} ->
          from(i in Ident.User.ExtId, where: i.origin == ^o and i.user_id == ^u_id)
          |> Repo.delete_all()
        end)

        {:ok, u}
      end
    end)
  end

  @delete_type User.Code.type!(:delete_request)
  def delete_account(%User{} = user, code) when is_binary(code) do
    case User.Code.one(code: code, user_id: user.id) do
      {:ok, %{type: @delete_type} = code} ->
        if DateTime.before?(DateTime.utc_now(), code.expires) do
          # TODO: verify code isn't expired
          delete_account(user)
        else
          {:error, "Unable to continue"}
        end

      _ ->
        {:error, "Unable to continue"}
    end
  end

  ##############################################################################
  @doc """
  ```
  iex> get_user("asdf")
  {:error, :not_found}

  iex> get_user("A73DD874-A724-494F-B9E2-2042A4383144")
  {:error, :not_found}

  iex> handle = insert(:ident_handle)
  iex> {:ok, u} = get_user(handle.user_id)
  iex> u.id
  handle.user_id

  iex> handle = insert(:ident_handle)
  iex> {:ok, u} = get_user(handle.handle, [:handle])
  iex> u.id
  handle.user_id
  ```
  """
  def get_user(id, preload \\ [])

  def get_user(id, preload) when is_binary(id) and byte_size(id) == 36 do
    with {:error, :not_found} <- User.one([id: id], preload) do
      get_user_by_handle(id, preload)
    end
  end

  def get_user(id, preload), do: get_user_by_handle(id, preload)

  def get_user_by_handle(id, preload \\ []) do
    with {:ok, %{user} = handle} <- Handle.one([handle: id], [:user]) do
      User.preload(%User{user | handle}, preload)
    end
  end
end
