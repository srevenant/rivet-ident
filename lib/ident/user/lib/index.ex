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
      with {:ok, user} <- User.update(user, %{last_seen: now}) do
        Rivet.Ident.Factor.Cache.update_user(user)
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

  # ##############################################################################
  # def send_password_reset(%User{} = user, %Email{} = email, %User.Code{} = code) do
  #   # let all emails on the account know
  #   with {:ok, user} <- User.preload(user, [:emails]) do
  #     sendmail(user.emails, &templates.password_reset/2, [email, code])
  #   end
  # end
  #
  # ##############################################################################
  # def send_failed_change(%Email{} = email, message) do
  #   sendmail(email, &templates.failed_change/2, message)
  # end
  #
  # ##############################################################################
  # def send_password_changed(%User{} = user) do
  #   with {:ok, user} <- User.preload(user, [:emails]) do
  #     sendmail(user.emails, &templates.password_changed/2)
  #   end
  # end

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

        # add it
        case Email.create(%{
               address,
               user_id: user.id,
               verified: Map.get(opts, :verified, false),
               primary: not has_email?
             }) do
          {:ok, %Email{} = email} ->
            if opts[:no_send] != true,
              do: send_verify_email(%Email{email | user: user})

            {:ok, email}

          {:error, chgset} ->
            {:error, Rivet.Ecto.Errors.convert_error_changeset(chgset)}
        end
    end
  end

  def send_verify_email(%Email{address: eaddr} = email, _ \\ nil) do
    Logger.info("verify email", user_id: email.user_id, eaddr: eaddr)
    Rivet.Ident.mailer_template(:user_verification).queue(email)
  end

  ##############################################################################
  def check_user_status(%User{type: :disabled}),
    do: {:error, %Auth.Domain{error: "sorry, account is disabled"}}

  def check_user_status(%User{} = user), do: {:ok, user}
  def check_user_status(%Auth.Domain{user: %User{} = user}), do: check_user_status(user)
  def check_user_status(%Auth.Domain{} = pass), do: {:ok, pass}

  ##############################################################################
  def user_enabled?(%User{type: :disabled}), do: false
  def user_enabled?(%User{}), do: true

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
            {:error, Rivet.Ecto.Errors.convert_error_changeset(chgset)}
        end
    end
  end

  ##############################################################################
  @spec has_other_admin?(Ident.Role.t(), User.t()) :: boolean() | {:error, String.t()}
  def has_other_admin?(%Ident.Role{name: :system_admin, id: r_id}, %User{id: user_id}) do
    query = from(a in Ident.Access, where: a.role_id == ^r_id and a.user_id != ^user_id)

    if User.aggregate(query, :count) > 0 do
      true
    else
      {:error, "Cannot remove last system_admin"}
    end
  end

  def has_other_admin?(_, _), do: true

  ##############################################################################
  def delete_each([nil | rest], mod), do: delete_each(rest, mod)

  def delete_each([x | rest], mod) do
    with {:ok, _} <- mod.delete(x), do: delete_each(rest, mod)
  end

  def delete_each([], _), do: :ok

  @doc """

  We don't actually delete the base account, so we have to do the related things
  by hand, where we do want to sanitize them.

  iex> u = insert(:ident_user)
  iex> {:ok, _} = delete_account(u)

  """
  # , :mailer_subs]
  @preloads [:emails, :factors, :handle, :ext_ids, :phones]
  def delete_account(%User{} = u) do
    with {:ok, u} <- User.preload(u, @preloads),
         {:ok, u} <- User.update(u, %{name: "DELETED", type: :disabled}),
         :ok <- delete_each(u.emails, Email),
         # :ok <- delete_each(u.mailer_subs, Rivet.Mailer.Subs),
         :ok <- delete_each([u.handle], Ident.Handle),
         :ok <- delete_each(u.phones, Ident.Phone),
         :ok <- delete_each(u.factors, Ident.Factor) do
      # different primary key
      u_id = u.id

      Enum.each(u.ext_ids, fn %{origin: o} ->
        from(i in Ident.User.ExtId, where: i.origin == ^o and i.user_id == ^u_id)
        |> Repo.delete_all()
      end)

      {:ok, u}
    end
  end

  def delete_account(%User{} = user, code) when is_binary(code) do
    expires = Application.get_env(:core, :user_code_expires)[:delete_request]

    case User.Code.one(code: code, user_id: user.id) do
      {:ok, code} ->
        if DateTime.diff(DateTime.utc_now(), code.inserted_at, :minute) > expires do
          {:error, "Unable to continue"}
        else
          # TODO: verify code isn't expired
          delete_account(user)
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
    with {:error, _} <- User.one([id: id], preload) do
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
