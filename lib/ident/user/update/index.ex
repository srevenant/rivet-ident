defmodule Rivet.Ident.User.Update do
  @moduledoc """

  Making changes to a user (administratively or as the user). Update scans through
  args for known change keys (:email, :data, etc) but ONLY changes the first one
  it encounters, so do not stack changes.

  """

  use Rivet.Ident
  require Logger
  use Rivet.Ecto.Collection.Context, model: User

  @spec update(change_map :: map(), target_user :: User.t(), opts :: keyword()) ::
          {:ok, User.t()} | {:error, reason :: String.t() | atom()}

  @changeable [:user, :email, :data, :handle, :phone, :role]
  def update(args, %User{} = target, opts \\ []),
    do: update_scan(@changeable, args, target, opts)

  defp update_scan([key | rest], args, target, opts) do
    update = args[key]

    if is_map(update) and map_size(update) > 0 do
      # I could do a single function stack, but I want to be able to have helper
      # functions in orbit to each while in proximity to the parent
      updater = String.to_existing_atom("update_#{key}")
      apply(__MODULE__, updater, [args[:action], update, target, opts])
    else
      update_scan(rest, args, target, opts)
    end
  end

  defp update_scan([], _, _, _), do: {:error, "No updates found"}

  ##############################################################################
  # upsert in this case is update, since we require an existing target
  def update_user(:upsert, %{disable}, %User{} = u, opts) do
    # only admin can enable/disable;
    if opts[:auth] == :admin and is_boolean(disable) do
      # on enable set to identity (next signin will fix)
      disabled = if disable, do: :disabled, else: :identity

      User.update(u, %{type: disabled})
      |> tap(fn
        {:ok, %{type: :disabled} = u} ->
          # clear cache but don't disrupt this task
          mailer_template(:critical_fail).unattended_task(fn ->
            Rivet.Ident.Factor.Cache.invalidate_all_for(u.id)
          end)

        _ ->
          :ok
      end)
    else
      bad_args("user/disable")
    end
  end

  def update_user(:upsert, update, %User{} = target, _opts) do
    # note: empty_str(nil) is false, since nil is not a string and thus can't be empty
    # its clunky to do this here, but for various reasons name is NOT required on
    # the model, so this is an easier path to assert it for user changes.
    case update do
      %{name} when empty_str(name) -> {:error, "You must provide a name"}
      %{type: _} -> {:error, "Update of type is disallowed"}
      update -> User.update(target, update)
    end
  end

  def update_user(_, _, _, _), do: bad_args("user")

  ##############################################################################
  def update_phone(:upsert, %{number}, %User{} = target, _opts) do
    with {:ok, _} <- User.Lib.add_phone(target, number), do: refresh(target, :phones)
  end

  def update_phone(:remove, %{id: phone_id}, %User{} = target, _opts) when is_uuid(phone_id) do
    user_id = target.id

    case Ident.Phone.one(id: phone_id) do
      {:ok, %Ident.Phone{user_id: ^user_id} = phone} ->
        with {:ok, _} <- Ident.Phone.delete(phone), do: refresh(target, :phones)

      _ ->
        {:error, :not_found}
    end
  end

  def update_phone(_, _, _, _), do: bad_args("phone")

  ##############################################################################
  # HANDLE
  def update_handle(:upsert, %{handle}, %User{} = target, _opts) when not_empty_str(handle) do
    with {:ok, target} <- User.preload(target, [:handle]) do
      case Handle.Lib.available(handle, target.id) do
        {:ok, :current} ->
          refresh(target, :handle)

        {:ok, :available} ->
          @repo.transact(fn ->
            with {:ok, _} <- delete_old_handle(target.handle),
                 {:ok, _} <- Handle.create(%{handle, user_id: target.id}),
                 do: refresh(target, :handle)
          end)

        {:error, private, public} ->
          Logger.error(private)
          {:error, public}
      end
    end
  end

  def update_handle(_, _, _, _), do: bad_args("handle")

  # delete the old one, if there is one (should be), but if not still pretend it was deleted
  defp delete_old_handle(%Handle{} = h), do: Handle.delete(h)
  defp delete_old_handle(_), do: {:ok, nil}

  ##############################################################################
  # verify as in SEND verification, not change it
  def update_email(:upsert, %{id: email_id, verify: true}, %User{id: user_id} = u, _opts) do
    with {:ok, %Email{user_id: ^user_id} = email} <- Email.one([id: email_id], [:user]) do
      Rivet.Ident.mailer_template(:user_verification).queue(email)
      refresh(u, :emails)
    end
  end

  def update_email(:upsert, %{address}, %User{} = u, opts) when is_binary(address) do
    with {:ok, %Email{} = e} <- User.Lib.add_email(u, address, opts) do
      User.Lib.send_verify_email(%{u | emails: [e]})
      refresh(u, :emails)
    end
  end

  def update_email(:remove, %{id: email_id}, %User{id: user_id} = u, _opts) do
    with {:ok, %Email{user_id: ^user_id} = email} <- Email.one(id: email_id),
         {:ok, _email} <- Email.delete(email),
         do: refresh(u, :emails)
  end

  def update_email(_, _, _, _), do: bad_args("email")

  ##############################################################################
  def update_data(:upsert, %{id, value}, %User{} = user, _) do
    with {:ok, current} <- User.Data.one(id: id, user_id: user.id),
         {:ok, _} <- User.Data.update(current, %{value}),
         do: refresh(user, :data)
  end

  def update_data(:upsert, %{type, value}, %User{id: user_id} = user, _) do
    with {:ok, _} <- User.Data.create(%{user_id, type, value}), do: refresh(user, :data)
  end

  def update_data(:remove, %{id}, %User{} = user, _) do
    with {:ok, current} <- User.Data.one(id: id, user_id: user.id),
         {:ok, _} <- User.Data.delete(current),
         do: refresh(user, :data)
  end

  def update_data(_, _, _, _), do: bad_args("data")

  ################################################################################
  def update_role(action, %{id: role_id}, %User{} = u, opts) when is_integer(role_id) do
    case opts[:auth] do
      :admin ->
        case Ident.Role.one(id: role_id) do
          {:ok, %Ident.Role{} = role} ->
            access = Ident.Access.one(user_id: u.id, role_id: role_id)
            update_role_(action, access, role, u)

          {:error, :not_found} ->
            bad_args("role/missing")
        end

      _ ->
        # Logger for unauthz?
        bad_args("role/auth")
    end
  end

  def update_role(_, _, _, _), do: bad_args("role")

  #######
  defp update_role_(:upsert, {:ok, _}, _, u), do: refresh(u, :accesses)

  defp update_role_(:upsert, {:error, :not_found}, %{id: role_id}, %{id: user_id} = u) do
    with {:ok, _} <- Ident.Access.upsert(%{role_id, user_id}),
         :ok <- clear_auth_cache(user_id),
         do: refresh(u, :accesses)
  end

  defp update_role_(:remove, {:ok, access}, _, u) do
    with {:ok, _} <- Ident.Access.delete(access),
         :ok <- clear_auth_cache(u.id),
         do: refresh(u, :accesses)
  end

  defp update_role_(_, _, _, _), do: bad_args("role/args")

  defp clear_auth_cache(user_id) do
    Rivet.Auth.Cache.delete(user_id)
    :ok
  end

  ##############################################################################
  defp refresh(user, key), do: User.preload(user, key, force: true)
  defp bad_args(what), do: {:error, "Invalid #{what} change configuration"}
end
