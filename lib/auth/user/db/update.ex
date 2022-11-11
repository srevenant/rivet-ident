defmodule Rivet.Data.Auth.User.Db.Update do
  @moduledoc """
  Making changes to a user (administratively or as the user).

  See UsersUpdate.update @spec for details on args.  Explains for said args:

  - `user_changes` map is variable, in that it's keys may vary based on the input
    args sent into GraphQL updatePerson() mutation
  - `caller_authz` is the level of authorization for the caller, which changes
    what updates are allowed.
  - `target_user` is optional, if nil the user should be created, if exists then
    it's an update for that user

  Example (create):

    ```elixir
    ==> Rivet.Data.Auth.UsersUpdate.update(%{
        action: :upsert,
        tenant_id: "e6e392fb-e4e1-4e81-ae52-a7692f8e9534",
        user: %{name: "The Doctor"},
        email: %{email: "who@tardis.com"}
      }, :admin)
    {:ok, %User{}, %{"password": "R^EkW)aBY9G9", "passwordExp": 1649947803}}
    ```
    Rivet.Data.Auth.UsersUpdate.update(%{ action: :upsert, tenant_id: "e6e392fb-e4e1-4e81-ae52-a7692f8e9534", user: %{name: "The Doctor"}, email: %{email: "who@tardis.com"} }, :admin)

    Example — update a user's name as the user

    ```elixir
    ==> Rivet.Data.Auth.UsersUpdate.update(%{
      action: :upsert,
      user: %{name: "Who"},
    }, :user, %User{...})
    {:ok, %User{}, %{}}
    ```

    Example — remove a phone

    ```elixir
    ==> Rivet.Data.Auth.UsersUpdate.update(%{
      action: :remove,
      phone: %{id: "2342343-...-33"},
    }, :user, %User{...})
    {:ok, %User{}, %{}}
    ```

  """
  use Rivet.Ecto.Collection.Context
  alias Rivet.Data.Auth
  require Logger

  @spec update(
          user_changes :: map(),
          caller_authz :: :admin | :user,
          target_user :: Auth.User.t() | nil
        ) ::
          {:ok, Auth.User.t()}
          | {:error, reason :: String.t()}

  def update(x, auth \\ :user, user \\ nil)

  # USER CREATE NEW — special variant
  def update(%{user: %{}, tenant_id: t_id, action: :upsert} = args, :admin, nil)
      when is_binary(t_id) do
    with {:ok, args} <- preflight_user_create(args, t_id),
         {:ok, user} <- Auth.User.create(args.user) do
      generated = Auth.User.PasswordGenerator.generate()

      expires_at =
        Rivet.Utils.Time.now() + get_user_conf(:initial_password_expiration_days) * 86_400

      with {:ok, factor} <-
             Auth.Factor.Db.set_password(user, generated, %{expires_at: expires_at}) do
        finish_update(
          args,
          :user,
          :admin,
          %Auth.User{user | factors: [%{factor | details: %{"password" => generated}}]}
        )
      end
    end
  end

  # USER UPDATE
  def update(%{user: updates, action: :upsert} = args, admin, %Auth.User{} = user) do
    updates =
      case {admin, Map.get(updates, :disable)} do
        {:admin, true} ->
          Map.put(updates, :type, :disabled)

        {:admin, false} ->
          Map.put(updates, :type, :identity)

        _pass ->
          updates
      end

    with {:ok, user} <- Auth.User.update(user, updates) do
      finish_update(args, :user, admin, user)
    end
  end

  def update(%{user: _}, _, _), do: {:error, "Invalid user change configuration"}

  ##############################################################################
  # PHONE
  def update(%{phone: %{phone: phone}, action: :upsert} = args, admin, %Auth.User{} = user) do
    with {:ok, _} <- Auth.User.Db.add_phone(user, phone),
         do: finish_update(args, :phone, admin, refresh(user, :phones))
  end

  def update(%{phone: %{id: phone_id}, action: :remove} = args, admin, %Auth.User{} = user) do
    user_id = user.id

    with {:ok, %Auth.UserPhone{user_id: ^user_id} = phone} <- Auth.UserPhone.one(id: phone_id),
         {:ok, _} <- Auth.UserPhone.delete(phone) do
      finish_update(args, :phone, admin, refresh(user, :phones))
    end
  end

  def update(%{phone: _}, _, _), do: {:error, "Invalid phone change configuration"}

  ##############################################################################
  # HANDLE
  def update(%{handle: %{handle: handle}, action: :upsert} = args, admin, %Auth.User{} = user)
      when is_binary(handle) do
    # inner with so the error can have the preloaded user
    with {:ok, user} <- Auth.User.preload(user, [:handle]) do
      with {:ok, :available} <- Auth.UserHandle.Db.available(handle, user.id),
           {:ok, new} <-
             Auth.UserHandle.create(%{
               handle: handle,
               user_id: user.id,
               tenant_id: user.tenant_id
             }) do
        # delete the old one
        with %Auth.UserHandle{} <- user.handle, do: Auth.UserHandle.delete(user.handle)

        finish_update(args, :handle, admin, %Auth.User{user | handle: new})
      else
        # we already have this handle
        {:ok, :current} ->
          finish_update(args, :handle, admin, user)

        {:error, private, public} ->
          Logger.error(private)
          {:error, public}

        pass ->
          pass
      end
    end
  end

  def update(%{handle: _}, _, _), do: {:error, "Invalid handle change configuration"}

  ##############################################################################
  def update(
        %{email: %{id: email_id, verify: true}, action: :upsert} = args,
        admin,
        %Auth.User{id: user_id} = user
      ) do
    with {:ok, %Auth.UserEmail{user_id: ^user_id} = email} <-
           Auth.UserEmail.one([id: email_id], [:user]) do
      Auth.User.Notify.Verification.send(email)
      finish_update(args, :email, admin, user)
    end
  end

  def update(%{email: %{email: email}, action: :upsert} = args, admin, %Auth.User{} = user) do
    with {:ok, _email} <- Auth.User.Db.add_email(user, email) do
      finish_update(args, :email, admin, refresh(user, :emails))
    end
  end

  def update(
        %{email: %{id: email_id}, action: :remove} = args,
        admin,
        %Auth.User{id: user_id} = user
      ) do
    with {:ok, %Auth.UserEmail{user_id: ^user_id} = email} <- Auth.UserEmail.one(id: email_id),
         {:ok, _email} <- Auth.UserEmail.delete(email) do
      finish_update(args, :email, admin, refresh(user, :emails))
    end
  end

  def update(%{email: _}, _, _), do: {:error, "Invalid email change configuration"}

  ##############################################################################
  def update(%{data: data, action: :upsert} = args, admin, %Auth.User{} = user) do
    case data do
      %{id: id} ->
        with {:ok, current} <- Auth.UserData.one(id: id, user_id: user.id) do
          Auth.UserData.update(current, %{value: data.value})
        end

      _new ->
        Auth.UserData.create(%{user_id: user.id, type: data.type, value: data.value})
    end
    |> case do
      {:ok, %Auth.UserData{}} ->
        finish_update(args, :data, admin, refresh(user, :data))

      {:error, %Ecto.Changeset{}} = err ->
        err

      _other ->
        {:error, "unable to update with user data"}
    end
  end

  ################################################################################
  def update(%{role: role_arg, action: :upsert} = args, :admin, %Auth.User{} = user) do
    with {:ok, role} <- Auth.Role.one(Enum.to_list(role_arg)),
         {:error, _} <- Auth.Access.one(user_id: user.id, role_id: role.id),
         {:ok, _} <- Auth.Access.upsert(%{role_id: role.id, user_id: user.id}) do
      finish_update(args, :role, :admin, refresh(user, :accesses))
    end
  end

  def update(%{role: role_arg, action: :remove} = args, :admin, %Auth.User{} = user) do
    with {:ok, role} <- Auth.Role.one(Enum.to_list(role_arg)),
         {:ok, access} <- Auth.Access.one(user_id: user.id, role_id: role.id),
         true <- Auth.User.Db.has_other_admin?(role, user),
         {:ok, _} <- Auth.Access.delete(access) do
      finish_update(args, :role, :admin, refresh(user, :accesses))
    end
  end

  # ##############################################################################
  # def mutate_update_role(%{role: role, id: user_id}, info)
  #     when not is_nil(role) and not is_nil(user_id) do
  #   with {:ok, admin} <- authz_action(info, %AuthAssertion{action: :user_admin}, "updateRole"),
  #        {:user, {:ok, user}} <- {:user, Auth.User.one(id: user_id, tenant_id: admin.tenant_id)},
  #        {:role, {:ok, role}} <- {:role, Auth.Role.one(id: role)},
  #        {:has_admin, true} <-
  #          {:has_admin, Auth.User.Db.tenant_has_other_admin?(user_id, admin.tenant_id)} do
  #     case Auth.Access.one(user_id: user.id, role_id: role.id) do
  #       {:ok, _access} ->
  #         nil
  #
  #       {:error, _} ->
  #         Auth.Access.upsert(%{role_id: role.id, user_id: user.id})
  #     end
  #
  #     {:ok, %{success: true, result: Auth.User.preload!(user, [:accesses], force: true)}}
  #   else
  #     {:user, {:error, _}} ->
  #       {:error, reason} = graphql_error("updateRole", "Couldn't find user with given ID.")
  #       {:ok, %{success: false, reason: reason}}
  #
  #     {:role, {:error, _}} ->
  #       {:error, reason} = graphql_error("updateRole", "Couldn't find role with given ID")
  #       {:ok, %{success: false, reason: reason}}
  #
  #     {:has_admin, false} ->
  #       {:error, reason} = graphql_error("updateRole", "Not allowed. No other admin exists.")
  #       {:ok, %{success: false, reason: reason}}
  #   end
  # end

  ################################################################################
  def update(_, _, user), do: {:ok, user}

  ##############################################################################
  defp get_user_conf(key), do: Application.get_env(:authx, key)

  ##############################################################################
  defp finish_update(args, did_type, admin, user),
    do: update(Map.delete(args, did_type), admin, user)

  ##############################################################################
  def preflight_user_create(%{user: _} = args, t_id) do
    with {:ok, args} <- enrich_create(args, :handle, t_id),
         {:ok, args} <- enrich_create(args, :email, t_id) do
      enrich_create(args, :user, t_id)
    end
  end

  ##############################################################################
  defp enrich_create(args, :user, t_id) do
    {:ok,
     Map.update(args, :user, %{}, fn u ->
       settings = Map.get(u, :settings, %{}) |> Map.put("changePassword", true)
       Map.merge(u, %{settings: settings, type: :identity, tenant_id: t_id})
     end)}
  end

  # Handle?
  defp enrich_create(%{handle: %{handle: h}} = args, :handle, t_id)
       when is_binary(h) and byte_size(h) > 0,
       do: enrich_handle(args, h, t_id)

  defp enrich_create(%{email: %{email: addr}} = args, :handle, t_id)
       when is_binary(addr) and byte_size(addr) > 0 do
    case get_in(args, [:handle, :handle]) do
      # if unspecified, auto-create a handle
      nil ->
        {:ok,
         Map.put(args, :handle, %{
           handle: Auth.UserHandle.Db.gen_good_handle(addr),
           tenant_id: t_id
         })}

      # or check the one they provide
      handle ->
        enrich_handle(args, handle, t_id)
    end
  end

  defp enrich_create(%{email: %{email: addr}} = args, :email, t_id) when is_binary(addr),
    do: create_ok(args, :email, :address, Auth.UserEmails, %{address: addr, email: addr}, t_id)

  defp create_ok(args, component, key, module, attrs, t_id) do
    # inject some for the query to keep create_ok happy
    check_args = Map.merge(%{user_id: "ignore", tenant_id: t_id}, attrs)

    case module.create_ok(check_args, [key]) do
      :ok ->
        {:ok, Map.put(args, component, attrs)}

      {:error, :exists} ->
        {:error, "Sorry that #{component} is already taken"}

      pass ->
        pass
    end
  end

  defp enrich_handle(args, name, t_id),
    do: create_ok(args, :handle, :handle, Auth.UserHandles, %{handle: name}, t_id)

  ##############################################################################
  defp refresh(user, key), do: Auth.User.preload!(user, key, force: true)
end
