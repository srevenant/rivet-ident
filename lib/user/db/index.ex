defmodule Cato.Data.Auth.User.Db do
  alias Cato.Data.Auth
  use Unify.Ecto.Collection.Context

  # alias Core.Email.SaasyTemplates
  # import Core.Email.Sendmail

  def search(%{tenant_id: tenant_id, matching: matching, limit: limit}) do
    {:ok,
     Repo.all(
       from(u in Auth.User,
         join: e in Auth.UserEmail,
         where: e.user_id == u.id,
         join: h in Auth.UserHandle,
         where: h.user_id == u.id,
         where:
           u.tenant_id == ^tenant_id and
             (like(u.name, ^matching) or
                like(h.handle, ^matching) or
                like(e.address, ^matching)),
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
  @spec get_authz(user :: Auth.User.t()) :: Auth.User.t()
  def get_authz(%Auth.User{authz: authz} = user) when is_nil(authz) do
    {:ok, user} = Auth.Users.preload(user, :accesses)
    %Auth.User{user | authz: Cato.Data.Auth.Accesses.get_actions(user)}
  end

  def get_authz(%Auth.User{} = user), do: user

  @spec check_authz(user :: Auth.User.t(), Auth.AuthAssertion.t()) ::
          {:ok | :error, Auth.User.t()}
  def check_authz(user, %Auth.AuthAssertion{} = assertion) do
    key = {assertion.action, assertion.domain, assertion.ref_id}
    user = Auth.Users.get_authz(user)

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
  def user_seen(%Auth.User{} = user) do
    now = Timex.now()

    if is_nil(user.last_seen) or Timex.diff(now, user.last_seen, :seconds) > @update_min_seconds do
      with {:ok, user} <- update(user, %{last_seen: now}) do
        Auth.Factor.Cache.update_user(user)
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
  @type auth_result :: {:ok | :error, Auth.AuthDomain.t()}

  ################################################################################
  @doc """
  SignUp pipeline
  """

  ##############################################################################
  ### TODO: check email first, have signup shift to give an error: that user already exists, if it is found
  @spec signup(Auth.Tenant.t(), params :: map()) :: auth_result
  # def signup(tenant, %{handle: handle, email: email} = args)
  #     when handle == "",
  #     do: signup(tenant, Map.put(args, :handle, email))
  # def signup(tenant, %{handle: handle, email: email, password: password}) do
  #   {:ok, %Auth.AuthDomain{input: %{handle: handle, email: email, secret: password}, tenant: tenant}}

  def update_user(x, y), do: Auth.UsersUpdate.update(x, y)
  #
  #
  # TODO: Need to DRY this out with UsersUpdate module
  #
  #
  def signup(%Auth.AuthDomain{} = auth) do
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

  def signup(tenant, input) do
    {:error,
     %Auth.AuthDomain{
       log: "No match for signup with args:\n(#{inspect(tenant)}, #{inspect(input)}",
       error: "Sign up Failed"
     }}
  end

  # variant with less restrictions
  def signup_only_identity(%Auth.AuthDomain{} = auth) do
    {:ok, auth}
    |> signup_create_user(:identity)
    |> signup_associate_email
    |> mainline

    # TODO: this should actually shift to a welcome new user dialog, which can ask for other account attributes
  end

  # result is any as we ignore it
  @spec signup_abort_create(Auth.AuthDomain.t()) ::
          {:ok, Auth.User.t()} | {:error, Ecto.Changeset.t()}
  defp signup_abort_create(auth) do
    if not is_nil(auth.user) do
      Auth.Users.delete(auth.user)
    end
  end

  defp signup_check_handle(pass = {:ok, auth = %Auth.AuthDomain{input: %{handle: handle}}}) do
    case Auth.UserHandles.available(handle) do
      {:ok, _available_msg} ->
        pass

      {:error, private, public} ->
        {:error, auth, {private, public}}
    end
  end

  defp signup_create_user(
         {:ok, auth = %Auth.AuthDomain{tenant: tenant = %Auth.Tenant{}, input: input}},
         type
       ) do
    name = Map.get(input, :name, "")
    settings = Map.get(input, :settings, %{})

    case Auth.Users.create(%{
           name: name,
           settings: settings,
           tenant: tenant,
           tenant_id: tenant.id,
           type: type
         }) do
      #    case Map.merge(params, %{tenant: tenant, tenant_id: tenant.id}) |> Auth.Users.create() do
      {:ok, user} ->
        {:ok, %Auth.AuthDomain{auth | status: type, user: user, created: true}}

      {:error, err} ->
        signup_abort_create(auth)
        {:error, auth, {"Failed to create user=#{inspect(err)}", "Unable to signup at this time"}}
    end
  end

  defp signup_add_factor({:error, _auth, _reason} = pass), do: pass

  defp signup_add_factor(
         {:ok,
          auth = %Auth.AuthDomain{
            user: %Auth.User{} = user,
            input: %{secret: secret}
          }}
       ) do
    case Auth.Factors.set_password(user, secret) do
      {:ok, %Auth.Factor{}} ->
        {:ok, auth}

      {:error, %Changeset{} = changeset} ->
        signup_abort_create(auth)
        {:error, auth, {"", Utils.Errors.convert_error_changeset(changeset)}}
    end
  end

  defp signup_add_factor(
         {:ok,
          auth = %Auth.AuthDomain{
            user: %Auth.User{} = user,
            input: %{fedid: %Auth.AuthFedId{} = fedid}
          }}
       ) do
    case Auth.Factors.set_factor(user, fedid) do
      {:ok, %Auth.Factor{} = factor} ->
        {:ok, %Auth.AuthDomain{auth | factor: factor}}

      {:error, %Changeset{} = changeset} ->
        signup_abort_create(auth)
        {:error, auth, {"", Utils.Errors.convert_error_changeset(changeset)}}
    end
  end

  defp signup_associate_handle({:error, _auth, _reason} = pass), do: pass

  defp signup_associate_handle(
         {:ok,
          auth = %Auth.AuthDomain{
            tenant: %Auth.Tenant{} = tenant,
            user: %Auth.User{} = user,
            input: %{handle: handle}
          }}
       ) do
    case Auth.UserHandles.create(%{handle: handle, user_id: user.id, tenant_id: tenant.id}) do
      {:ok, handle} ->
        {:ok, %Auth.AuthDomain{auth | handle: handle}}

      {:error, %Changeset{} = changeset} ->
        signup_abort_create(auth)

        {:error, auth, {"", Utils.Errors.convert_error_changeset(changeset)}}
    end
  end

  defp signup_associate_email({:error, _auth, _reason} = pass), do: pass

  defp signup_associate_email(
         {:ok,
          auth = %Auth.AuthDomain{
            tenant: %Auth.Tenant{},
            user: %Auth.User{} = user,
            input: %{email: %{address: eaddr, verified: status}}
          }}
       )
       when is_binary(eaddr) do
    case add_email(user, eaddr, status) do
      {:ok, email} ->
        {:ok, %Auth.AuthDomain{auth | email: email}}

      {:error, msg} ->
        signup_abort_create(auth)
        {:error, auth, {"", msg}}
    end
  end

  # TODO: merge better with learning resolver--that code should probably be here
  defp signup_add_new_user({:ok, auth = %Auth.AuthDomain{user: %Auth.User{} = user}}) do
    with {:ok, user} <-
           Auth.Users.update(user, %{settings: Map.put(user.settings, "newUser", true)}) do
      {:ok, %Auth.AuthDomain{auth | user: user}}
    end
  end

  defp signup_add_new_user({:error, _, _} = pass), do: pass

  ##############################################################################
  defp signup_promote_first_user({:ok, auth = %Auth.AuthDomain{user: %Auth.User{} = user}}) do
    # except once use case this will be false
    if Application.get_env(:core, :first_user_admin) do
      Enum.each(Application.get_env(:core, :first_user_roles), fn role_name ->
        case Auth.Roles.one(name: role_name) do
          {:ok, role} ->
            case Auth.Accesses.create(%{role_id: role.id, user_id: user.id}) do
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

      Application.put_env(:core, :first_user_admin, false)
    end

    {:ok, auth}
  end

  defp signup_promote_first_user({:error, _, _} = pass), do: pass

  # after success, create a new struct so we don't carry around unecessary or
  # insecure baggage
  defp mainline({:ok, auth = %Auth.AuthDomain{}}) do
    {:ok,
     %Auth.AuthDomain{
       user: auth.user,
       tenant: auth.tenant,
       handle: auth.handle,
       created: auth.created,
       status: auth.status
     }}
  end

  defp mainline({:error, _auth, {inner, outer}}) do
    {:error, %Auth.AuthDomain{log: inner, error: outer}}
  end

  def active_users!(_since) do
    # GamePlatformTypeEnums.values()
    # |> Enum.reduce(%{}, fn platform, acc ->
    #   p = Atom.to_string(platform)
    #
    #   Map.put(
    #     acc,
    #     platform,
    #     Repo.one(
    #       from(u in Auth.User,
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

  def search_name!(tenant, pattern) do
    Repo.all(from(u in Auth.User, where: u.tenant_id == ^tenant and like(u.name, ^pattern)))
  end

  ##############################################################################
  @doc """
  Helper function which accepts either user_id or user, and calls the passed
  function with the user model loaded including any preloads.  Send preloads
  as [] if none are desired.
  """
  def with_user(%Auth.User{} = user, preloads, func) do
    with {:ok, user} <- Auth.Users.preload(user, preloads) do
      func.(user)
    end
  end

  def with_user(user_id, preloads, func) when is_binary(user_id) do
    case Auth.Users.one(user_id, preloads) do
      {:error, _} = pass ->
        pass

      {:ok, %Auth.User{} = user} ->
        func.(user)
    end
  end

  #
  # ##############################################################################
  # def send_password_reset(%Auth.User{} = user, %Auth.UserEmail{} = email, %Auth.UserCode{} = code) do
  #   # let all emails on the account know
  #   with {:ok, user} <- Auth.Users.preload(user, :emails) do
  #     sendmail(user.emails, &SaasyTemplates.password_reset/2, [email, code])
  #   end
  # end
  #
  # ##############################################################################
  # def send_failed_change(%Auth.UserEmail{} = email, message) do
  #   sendmail(email, &SaasyTemplates.failed_change/2, message)
  # end
  #
  # ##############################################################################
  # def send_password_changed(%Auth.User{} = user) do
  #   with {:ok, user} <- Auth.Users.preload(user, :emails) do
  #     sendmail(user.emails, &SaasyTemplates.password_changed/2)
  #   end
  # end

  ##############################################################################
  def all_since(time) do
    Repo.all(from(u in Auth.User, where: u.last_seen > ^time))
  end

  # ##############################################################################
  # @code_expire_mins 1440
  # def add_email(user, eaddr, verified \\ false) do
  #   eaddr = String.trim(eaddr)
  #
  #   # basic
  #   case Auth.UserEmails.one(tenant_id: user.tenant_id, address: eaddr) do
  #     {:ok, %Auth.UserEmail{} = email} ->
  #       Logger.warn("failed adding email", user_id: user.id, eaddr: eaddr)
  #       sendmail(email, &SaasyTemplates.failed_change/2, "add email to your account.")
  #
  #       {:error, "That email already is associated with a different account"}
  #
  #     {:error, _} ->
  #       # add it
  #       case Auth.UserEmails.create(%{
  #              user_id: user.id,
  #              tenant_id: user.tenant_id,
  #              verified: verified,
  #              address: eaddr
  #            }) do
  #         {:ok, %Auth.UserEmail{} = email} ->
  #           email = %Auth.UserEmail{email | user: user}
  #           send_verify_email(email)
  #
  #           {:ok, email}
  #
  #         {:error, chgset} ->
  #           {:error, Utils.Errors.convert_error_changeset(chgset)}
  #       end
  #   end
  # end
  #
  # def send_verify_email(%Auth.UserEmail{address: eaddr, user: user} = email) do
  #   with {:ok, code} <-
  #          Auth.UserCodes.generate_code(email.user_id, :email_verify, @code_expire_mins, %{
  #            email_id: email.id
  #          }) do
  #     Logger.info("added email", user_id: user.id, eaddr: eaddr)
  #     sendmail(email, &SaasyTemplates.verification/2, code)
  #   end
  # end

  def check_user_status({:ok, %Auth.AuthDomain{user: %Auth.User{type: :disabled}}}),
    do: {:error, %Auth.AuthDomain{error: "sorry, account is disabled"}}

  def check_user_status(%Auth.User{type: :disabled}) do
    {:error, %Auth.AuthDomain{error: "sorry, account is disabled"}}
  end

  def check_user_status(%Auth.User{} = user), do: {:ok, user}

  def check_user_status(pass) do
    pass
  end

  ##############################################################################
  def add_phone(user, phone) do
    # TODO: do an internal ph# validation
    phone = String.trim(phone)

    case Auth.UserPhones.one(user_id: user.id, number: phone) do
      {:ok, %Auth.UserPhone{} = phone} ->
        {:ok, phone}

      {:error, _} ->
        # add it
        case Auth.UserPhones.create(%{
               user_id: user.id,
               tenant_id: user.tenant_id,
               number: phone
             }) do
          {:ok, %Auth.UserPhone{} = phone} ->
            # TODO santity checks:
            # - pick primary
            # Logger.info("added phone", user_id: user.id, phone: phone)
            {:ok, phone}

          {:error, chgset} ->
            {:error, Utils.Errors.convert_error_changeset(chgset)}
        end
    end
  end

  ##############################################################################
  @spec tenant_has_other_admin?(Auth.Role.t(), Auth.User.t()) :: boolean() | {:error, String.t()}
  def tenant_has_other_admin?(%Auth.Role{name: :system_admin, id: r_id}, %Auth.User{id: user_id}) do
    query = from(a in Auth.Access, where: a.role_id == ^r_id and a.user_id != ^user_id)

    if Repo.aggregate(query, :count) > 0 do
      true
    else
      {:error, "Cannot remove last system_admin"}
    end
  end

  def tenant_has_other_admin?(_, _), do: true
end
