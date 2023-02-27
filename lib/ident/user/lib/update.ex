defmodule Rivet.Data.Ident.User.Lib.Update do
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
    ==> Rivet.Data.Ident.UsersUpdate.update(%{
        action: :upsert,
        user: %{name: "The Doctor"},
        email: %{email: "who@tardis.com"}
      }, :admin)
    {:ok, %User{}, %{"password": "R^EkW)aBY9G9", "passwordExp": 1649947803}}
    ```
    Rivet.Data.Ident.UsersUpdate.update(%{ action: :upsert, user: %{name: "The Doctor"}, email: %{email: "who@tardis.com"} }, :admin)

    Example — update a user's name as the user

    ```elixir
    ==> Rivet.Data.Ident.UsersUpdate.update(%{
      action: :upsert,
      user: %{name: "Who"},
    }, :user, %User{...})
    {:ok, %User{}, %{}}
    ```

    Example — remove a phone

    ```elixir
    ==> Rivet.Data.Ident.UsersUpdate.update(%{
      action: :remove,
      phone: %{id: "2342343-...-33"},
    }, :user, %User{...})
    {:ok, %User{}, %{}}
    ```

  """
  alias Rivet.Data.Ident
  require Logger

  @spec update(
          user_changes :: map(),
          caller_authz :: :admin | :user,
          target_user :: Ident.User.t() | nil
        ) ::
          {:ok, Ident.User.t()}
          | {:error, reason :: String.t()}

  def update(x, auth \\ :user, user \\ nil)

  # USER CREATE NEW — special variant
  def update(%{user: %{}, action: :upsert} = args, :admin, nil) do
    with {:ok, args} <- preflight_user_create(args),
         {:ok, user} <- Ident.User.create(args.user) do
      generated = Ident.User.PasswordGenerator.generate()

      expires_at =
        Rivet.Utils.Time.now() + get_user_conf(:initial_password_expiration_days) * 86_400

      with {:ok, factor} <-
             Ident.Factor.Lib.set_password(user, generated, %{expires_at: expires_at}) do
        finish_update(
          args,
          :user,
          :admin,
          %Ident.User{user | factors: [%{factor | details: %{"password" => generated}}]}
        )
      end
    end
  end

  # USER UPDATE
  def update(%{user: updates, action: :upsert} = args, admin, %Ident.User{} = user) do
    updates =
      case {admin, Map.get(updates, :disable)} do
        {:admin, true} ->
          Map.put(updates, :type, :disabled)

        {:admin, false} ->
          Map.put(updates, :type, :identity)

        _pass ->
          updates
      end

    with {:ok, user} <- Ident.User.update(user, updates) do
      finish_update(args, :user, admin, user)
    end
  end

  def update(%{user: _}, _, _), do: {:error, "Invalid user change configuration"}

  ##############################################################################
  # PHONE
  def update(%{phone: %{phone: phone}, action: :upsert} = args, admin, %Ident.User{} = user) do
    with {:ok, _} <- Ident.User.Lib.add_phone(user, phone),
         do: finish_update(args, :phone, admin, refresh(user, :phones))
  end

  def update(%{phone: %{id: phone_id}, action: :remove} = args, admin, %Ident.User{} = user) do
    user_id = user.id

    with {:ok, %Ident.Phone{user_id: ^user_id} = phone} <- Ident.Phone.one(id: phone_id),
         {:ok, _} <- Ident.Phone.delete(phone) do
      finish_update(args, :phone, admin, refresh(user, :phones))
    end
  end

  def update(%{phone: _}, _, _), do: {:error, "Invalid phone change configuration"}

  ##############################################################################
  # HANDLE
  def update(%{handle: %{handle: handle}, action: :upsert} = args, admin, %Ident.User{} = user)
      when is_binary(handle) do
    # inner with so the error can have the preloaded user
    with {:ok, user} <- Ident.User.preload(user, [:handle]) do
      with {:ok, :available} <- Ident.Handle.Lib.available(handle, user.id),
           {:ok, new_handle} <- Ident.Handle.create(%{handle: handle, user_id: user.id}) do
        # delete the old one
        with %Ident.Handle{} <- user.handle, do: Ident.Handle.delete(user.handle)

        finish_update(args, :handle, admin, %Ident.User{user | handle: new_handle})
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
        %Ident.User{id: user_id} = user
      ) do
    with {:ok, %Ident.Email{user_id: ^user_id} = email} <-
           Ident.Email.one([id: email_id], [:user]) do
      Ident.User.Notify.Verification.send(email)
      finish_update(args, :email, admin, user)
    end
  end

  def update(%{email: %{email: email}, action: :upsert} = args, admin, %Ident.User{} = user) do
    with {:ok, _email} <- Ident.User.Lib.add_email(user, email) do
      finish_update(args, :email, admin, refresh(user, :emails))
    end
  end

  def update(
        %{email: %{id: email_id}, action: :remove} = args,
        admin,
        %Ident.User{id: user_id} = user
      ) do
    with {:ok, %Ident.Email{user_id: ^user_id} = email} <- Ident.Email.one(id: email_id),
         {:ok, _email} <- Ident.Email.delete(email) do
      finish_update(args, :email, admin, refresh(user, :emails))
    end
  end

  def update(%{email: _}, _, _), do: {:error, "Invalid email change configuration"}

  ##############################################################################
  def update(%{data: data, action: :upsert} = args, admin, %Ident.User{} = user) do
    case data do
      %{id: id} ->
        with {:ok, current} <- Ident.UserData.one(id: id, user_id: user.id) do
          Ident.UserData.update(current, %{value: data.value})
        end

      _new ->
        Ident.UserData.create(%{user_id: user.id, type: data.type, value: data.value})
    end
    |> case do
      {:ok, %Ident.UserData{}} ->
        finish_update(args, :data, admin, refresh(user, :data))

      {:error, %Ecto.Changeset{}} = err ->
        err

      _other ->
        {:error, "unable to update with user data"}
    end
  end

  ################################################################################
  def update(%{role: role_arg, action: :upsert} = args, :admin, %Ident.User{} = user) do
    with {:ok, role} <- Ident.Role.one(Enum.to_list(role_arg)),
         {:error, _} <- Ident.Access.one(user_id: user.id, role_id: role.id),
         {:ok, _} <- Ident.Access.upsert(%{role_id: role.id, user_id: user.id}) do
      finish_update(args, :role, :admin, refresh(user, :accesses))
    end
  end

  def update(%{role: role_arg, action: :remove} = args, :admin, %Ident.User{} = user) do
    with {:ok, role} <- Ident.Role.one(Enum.to_list(role_arg)),
         {:ok, access} <- Ident.Access.one(user_id: user.id, role_id: role.id),
         true <- Ident.User.Lib.has_other_admin?(role, user),
         {:ok, _} <- Ident.Access.delete(access) do
      finish_update(args, :role, :admin, refresh(user, :accesses))
    end
  end

  # ##############################################################################
  # def mutate_update_role(%{role: role, id: user_id}, info)
  #     when not is_nil(role) and not is_nil(user_id) do
  #   with {:ok, admin} <- authz_action(info, %AuthAssertion{action: :user_admin}, "updateRole"),
  #        {:user, {:ok, user}} <- {:user, Ident.User.one(id: user_id)},
  #        {:role, {:ok, role}} <- {:role, Ident.Role.one(id: role)},
  #        {:has_admin, true} <-
  #          {:has_admin, Ident.User.Lib.tenant_has_other_admin?(user_id, admin.tenant_id)} do
  #     case Ident.Access.one(user_id: user.id, role_id: role.id) do
  #       {:ok, _access} ->
  #         nil
  #
  #       {:error, _} ->
  #         Ident.Access.upsert(%{role_id: role.id, user_id: user.id})
  #     end
  #
  #     {:ok, %{success: true, result: Ident.User.preload!(user, [:accesses], force: true)}}
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
  def preflight_user_create(%{user: _} = args) do
    with {:ok, args} <- enrich_create(args, :handle),
         {:ok, args} <- enrich_create(args, :email) do
      enrich_create(args, :user)
    end
  end

  ##############################################################################
  defp enrich_create(args, :user) do
    {:ok,
     Map.update(args, :user, %{}, fn u ->
       settings = Map.get(u, :settings, %{}) |> Map.put("changePassword", true)
       Map.merge(u, %{settings: settings, type: :identity})
     end)}
  end

  # Handle?
  defp enrich_create(%{handle: %{handle: h}} = args, :handle)
       when is_binary(h) and byte_size(h) > 0,
       do: enrich_handle(args, h)

  defp enrich_create(%{email: %{email: addr}} = args, :handle)
       when is_binary(addr) and byte_size(addr) > 0 do
    case get_in(args, [:handle, :handle]) do
      # if unspecified, auto-create a handle
      nil ->
        {:ok, Map.put(args, :handle, %{handle: Ident.Handle.Lib.gen_good_handle(addr)})}

      # or check the one they provide
      handle ->
        enrich_handle(args, handle)
    end
  end

  defp enrich_create(%{email: %{email: addr}} = args, :email) when is_binary(addr),
    do: create_ok(args, :email, :address, Ident.Emails, %{address: addr, email: addr})

  defp create_ok(args, component, key, module, attrs) do
    # inject some for the query to keep create_ok happy
    check_args = Map.merge(%{user_id: "ignore"}, attrs)

    case module.create_ok(check_args, [key]) do
      :ok ->
        {:ok, Map.put(args, component, attrs)}

      {:error, :exists} ->
        {:error, "Sorry that #{component} is already taken"}

      pass ->
        pass
    end
  end

  defp enrich_handle(args, name),
    do: create_ok(args, :handle, :handle, Ident.Handles, %{handle: name})

  ##############################################################################
  defp refresh(user, key), do: Ident.User.preload!(user, key, force: true)
end
