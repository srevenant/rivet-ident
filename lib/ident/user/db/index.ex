defmodule Rivet.Data.Ident.User.Db do
  alias Rivet.Data.Ident
  use Rivet.Ecto.Collection.Context, model: Ident.User
  # use Rivet.Data.Ident.Config
  alias Rivet.Auth
  require Logger

  def search(%{matching: matching, limit: limit}) do
    {:ok,
     @repo.all(
       from(u in Ident.User,
         join: e in Ident.Email,
         where: e.user_id == u.id,
         join: h in Ident.Handle,
         where: h.user_id == u.id,
         where:
           like(u.name, ^matching) or
             like(h.handle, ^matching) or
             like(e.address, ^matching),
         limit: ^limit,
         distinct: u.id
       )
     )}
  rescue
    error ->
      {:error, error}
  end

  @doc """
  Bring in the list of authorized actions onto the user object (into :authz)

  Only load once, if authz is nil
  """
  @spec get_authz(user :: Ident.User.t()) :: Ident.User.t()
  def get_authz(%Ident.User{authz: authz} = user) when is_nil(authz) do
    {:ok, user} = Ident.User.preload(user, :accesses)
    %Ident.User{user | authz: Rivet.Data.Ident.Access.Db.get_actions(user)}
  end

  def get_authz(%Ident.User{} = user), do: user

  @spec check_authz(user :: Ident.User.t(), Auth.Assertion.t()) ::
          {:ok | :error, Ident.User.t()}
  def check_authz(user, %Auth.Assertion{} = assertion) do
    key = {assertion.action, assertion.domain, assertion.ref_id}
    user = Ident.User.Db.get_authz(user)

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

  ##############################################################################
  # @doc """
  # SignIn pipeline
  # """
  # def signin(%{handle: handle, password: password}, conn) do
  #   # going backwards here, but ohwell - BJG
  #   AuthX.Signin.check(conn, %{"handle" => handle, "password" => password})
  # end

  # redefined here instead of doing a circular import to AuthX
  @type auth_result :: {:ok | :error, Auth.Domain.t()}

  ################################################################################
  @doc """
  SignUp pipeline
  """

  ##############################################################################
  ### TODO: check email first, have signup shift to give an error: that user already exists, if it is found
  #
  #
  #
  #
  # TODO: Need to DRY this out with UsersUpdate module
  @spec signup(Auth.Domain.t()) :: auth_result
  def signup(%Auth.Domain{} = auth) do
    {:ok, auth}
    |> signup_check_handle
    |> signup_create_user(:authed)
    # |> signup_add_password
    # TODO: be intelligent
    |> signup_add_factor
    |> signup_associate_handle
    |> signup_associate_email
    |> signup_add_new_user
    |> signup_promote_first_user
    |> mainline

    # TODO: this should actually shift to a welcome new user dialog, which can ask for other account attributes
  end

  def signup(input) do
    {:error,
     %Auth.Domain{
       log: "No match for signup with args:\n(#{inspect(input)}",
       error: "Sign up Failed"
     }}
  end

  # variant with less restrictions
  def signup_only_identity(%Auth.Domain{} = auth) do
    {:ok, auth}
    |> signup_create_user(:identity)
    |> signup_associate_email
    |> mainline

    # TODO: this should actually shift to a welcome new user dialog, which can ask for other account attributes
  end

  # result is any as we ignore it
  @spec signup_abort_create(Auth.Domain.t()) ::
          {:ok, Ident.User.t()} | {:error, Ecto.Changeset.t()}
  defp signup_abort_create(auth) do
    if not is_nil(auth.user) do
      Ident.User.delete(auth.user)
    end
  end

  defp signup_check_handle(pass = {:ok, auth = %Auth.Domain{input: %{handle: handle}}}) do
    case Ident.Handle.Db.available(handle) do
      {:ok, _available_msg} ->
        pass

      {:error, private, public} ->
        {:error, auth, {private, public}}
    end
  end

  defp signup_create_user(
         {:ok, auth = %Auth.Domain{input: input}},
         type
       ) do
    name = Map.get(input, :name, "")
    settings = Map.get(input, :settings, %{})

    case Ident.User.create(%{
           name: name,
           settings: settings,
           type: type
         }) do
      {:ok, user} ->
        {:ok, %Auth.Domain{auth | status: type, user: user, created: true}}

      {:error, err} ->
        signup_abort_create(auth)
        {:error, auth, {"Failed to create user=#{inspect(err)}", "Unable to signup at this time"}}
    end
  end

  defp signup_add_factor({:error, _auth, _reason} = pass), do: pass

  defp signup_add_factor(
         {:ok,
          auth = %Auth.Domain{
            user: %Ident.User{} = user,
            input: %{secret: secret}
          }}
       ) do
    case Ident.Factor.Db.set_password(user, secret) do
      {:ok, %Ident.Factor{}} ->
        {:ok, auth}

      {:error, %Ecto.Changeset{} = changeset} ->
        signup_abort_create(auth)
        {:error, auth, {"", Rivet.Utils.Ecto.Errors.convert_error_changeset(changeset)}}
    end
  end

  defp signup_add_factor(
         {:ok,
          auth = %Auth.Domain{
            user: %Ident.User{} = user,
            input: %{fedid: %Ident.Factor.FedId{} = fedid}
          }}
       ) do
    case Ident.Factor.Db.set_factor(user, fedid) do
      {:ok, %Ident.Factor{} = factor} ->
        {:ok, %Auth.Domain{auth | factor: factor}}

      {:error, %Ecto.Changeset{} = changeset} ->
        signup_abort_create(auth)
        {:error, auth, {"", Rivet.Utils.Ecto.Errors.convert_error_changeset(changeset)}}
    end
  end

  defp signup_associate_handle({:error, _auth, _reason} = pass), do: pass

  defp signup_associate_handle(
         {:ok,
          auth = %Auth.Domain{
            user: %Ident.User{} = user,
            input: %{handle: handle}
          }}
       ) do
    case Ident.Handle.create(%{handle: handle, user_id: user.id}) do
      {:ok, handle} ->
        {:ok, %Auth.Domain{auth | handle: handle}}

      {:error, %Ecto.Changeset{} = changeset} ->
        signup_abort_create(auth)

        {:error, auth, {"", Rivet.Utils.Ecto.Errors.convert_error_changeset(changeset)}}
    end
  end

  defp signup_associate_email({:error, _auth, _reason} = pass), do: pass

  defp signup_associate_email(
         {:ok,
          auth = %Auth.Domain{
            user: %Ident.User{} = user,
            input: %{email: %{address: eaddr, verified: status}}
          }}
       )
       when is_binary(eaddr) do
    case add_email(user, eaddr, status) do
      {:ok, email} ->
        {:ok, %Auth.Domain{auth | email: email}}

      {:error, msg} ->
        signup_abort_create(auth)
        {:error, auth, {"", msg}}
    end
  end

  # TODO: merge better with learning resolver--that code should probably be here
  defp signup_add_new_user({:ok, auth = %Auth.Domain{user: %Ident.User{} = user}}) do
    with {:ok, user} <-
           Ident.User.update(user, %{settings: Map.put(user.settings, "newUser", true)}) do
      {:ok, %Auth.Domain{auth | user: user}}
    end
  end

  defp signup_add_new_user({:error, _, _} = pass), do: pass

  ##############################################################################
  if @ident_first_user_admin do
    defp signup_promote_first_user({:ok, auth = %Auth.Domain{user: %Ident.User{} = user}}) do
      # except once use case this will be false
      if Application.get_env(:rivet, :first_user_admin) != false do
        Enum.each(@first_user_roles, fn role_name ->
          case Ident.Role.one(name: role_name) do
            {:ok, role} ->
              case Ident.Access.create(%{role_id: role.id, user_id: user.id}) do
                {:ok, _} ->
                  Logger.warn("Adding role #{role.name} to first user #{user.id}")

                {:error, what} ->
                  IO.inspect(what, label: "Cannot add role for first user!")
                  Logger.error("Cannot add role #{role.name} for first user!")
              end

            {:error, _} ->
              Logger.error("Cannot find role #{role_name} for first user!")
          end
        end)

        Application.put_env(:rivet, :first_user_admin, false)
      end

      {:ok, auth}
    end
  end

  defp signup_promote_first_user({:error, _, _} = pass), do: pass

  # after success, create a new struct so we don't carry around unecessary or
  # insecure baggage
  defp mainline({:ok, auth = %Auth.Domain{}}) do
    {:ok,
     %Auth.Domain{
       user: auth.user,
       handle: auth.handle,
       created: auth.created,
       status: auth.status
     }}
  end

  defp mainline({:error, _auth, {inner, outer}}) do
    {:error, %Auth.Domain{log: inner, error: outer}}
  end

  def active_users!(_since) do
    # GamePlatformTypeEnums.values()
    # |> Enum.reduce(%{}, fn platform, acc ->
    #   p = Atom.to_string(platform)
    #
    #   Map.put(
    #     acc,
    #     platform,
    #     @repo.one(
    #       from(u in Ident.User,
    #         where:
    #           u.last_seen > ^since and
    #             fragment(
    #               """
    #               settings->'platform'->? IS NOT NULL
    #               """,
    #               ^p
    #             ),
    #         select: fragment("count(*)")
    #       )
    #     )
    #   )
    # end)
  end

  def search_name!(pattern) do
    @repo.all(from(u in Ident.User, where: like(u.name, ^pattern)))
  end

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

  #
  # ##############################################################################
  # def send_password_reset(%Ident.User{} = user, %Ident.Email{} = email, %Ident.UserCode{} = code) do
  #   # let all emails on the account know
  #   with {:ok, user} <- Ident.User.preload(user, :emails) do
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
  #   with {:ok, user} <- Ident.User.preload(user, :emails) do
  #     sendmail(user.emails, &templates.password_changed/2)
  #   end
  # end

  ##############################################################################
  def all_since(time) do
    @repo.all(from(u in Ident.User, where: u.last_seen > ^time))
  end

  ##############################################################################
  def add_email(user, eaddr, verified \\ false) do
    eaddr = String.trim(eaddr)

    # basic
    case Ident.Email.one(address: eaddr) do
      {:ok, %Ident.Email{} = email} ->
        Logger.warn("failed adding email", user_id: user.id, eaddr: eaddr)
        Ident.User.Notify.FailedChange.send(email, "add email to your account.")

        {:error, "That email already is associated with a different account"}

      {:error, _} ->
        # add it
        case Ident.Email.create(%{
               user_id: user.id,
               verified: verified,
               address: eaddr
             }) do
          {:ok, %Ident.Email{} = email} ->
            email = %Ident.Email{email | user: user}
            Ident.User.Notify.Verification.send(email)

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

    if @repo.aggregate(query, :count) > 0 do
      true
    else
      {:error, "Cannot remove last system_admin"}
    end
  end

  def has_other_admin?(_, _), do: true
end
