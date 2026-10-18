defmodule Rivet.Auth.Password do
  @moduledoc """
  Public interface to authentication and authorization functions.
  """
  use Rivet.Ident
  use Rivet.Ecto.Collection.Context, model: User.Code

  alias Rivet.Auth

  ##############################################################################
  @reset_type User.Code.type!(:password_reset)
  def change_password_code(%User.Code{type: @reset_type, user: %User{}} = code, new)
      when not_empty_str(new) do
    @repo.transact(fn ->
      # fresh copy
      case User.Code.one(id: code.id) do
        {:ok, %{type: @reset_type, used: false}} ->
          with :ok <- set_password_(code.user, new), do: User.Code.update(code, %{used: true})

        {:ok, _} ->
          {:error, "Password reset codes cannot be used more than once"}

        {:error, :not_found} ->
          {:error, "Unable to find password reset code"}
      end
    end)
  end

  def change_password_code(_, _), do: {:error, :args}

  ##############################################################################
  def change_password_matching(%User{} = user, current, new)
      when not_empty_str(new) and not_empty_str(current) do
    cond do
      current == new -> {:error, "New password is the same as old"}
      matching_password?(user, current) -> set_password_(user, new)
      true -> {:error, "Password change failure: current password mis-match"}
    end
  end

  def change_password_matching(_, _, _), do: {:error, :args}

  ##############################################################################
  defp set_password_(%User{} = user, new) do
    with {:ok, %Factor{}} <- Factor.Lib.set_password(user, new) do
      Ident.mailer_template(:password_changed).queue(user)
      :ok
    end
  end

  ##############################################################################
  ## used for direct user w/out %Auth.Domain{}
  def matching_password?(%User{} = user, password) do
    case load_password_factor(%Auth.Domain{user}) do
      {:ok, %Auth.Domain{factor: %Factor{hash}}} -> matching_password_hash?(hash, password)
      {:error, _} -> false
    end
  end

  ##############################################################################
  def matching_password_hash?(hash, password) when is_binary(hash) and not is_nil(hash),
    do: Factor.Password.verify(password, hash)

  def matching_password_hash?(_, _), do: false

  ##############################################################################
  ## used when there already is an %Auth.Domain{}
  def valid_password_factor(%Auth.Domain{} = auth, password) do
    case load_password_factor(auth) do
      {:ok, %Auth.Domain{factor: %Factor{hash}} = auth} ->
        if Auth.Password.matching_password_hash?(hash, password) do
          {:ok, %Auth.Domain{auth | status: :authed}}
        else
          factor_error(auth, "Password does not match")
        end

      _ ->
        factor_error(auth, "No password factor")
    end
  end

  ##############################################################################
  def load_password_factor(auth = %Auth.Domain{user: user = %User{}}) do
    case Factor.Lib.preloaded_with(user, :password) do
      %User{factors: []} = user ->
        Logger.metadata(uid: user.id)
        factor_error(auth, "No auth factor for user")

      # FUTURE: we could have the calling/matching function check each and
      # return differently on expired but matching password factors
      %User{factors: [%Factor{hash} = factor | _]} = user when not is_nil(hash) and hash != "N/A" ->
        Logger.metadata(uid: user.id)
        {:ok, %Auth.Domain{auth | factor}}

      error ->
        # database error
        # coveralls-ignore-start
        Logger.metadata(uid: user.id)
        Logger.error("Unable to preload factor", error: error)
        factor_error(auth, "Unexpected result from factor preload")
        # coveralls-ignore-stop
    end
  end

  # no user, no factor
  def load_password_factor(%Auth.Domain{} = auth),
    do: factor_error(auth, "No user to lookup factor")

  @invalid_log "Invalid Password"
  defp factor_error(%Auth.Domain{} = auth, log),
    do: {:error, %{auth | log, status: :unknown, error: @invalid_log, factor: nil}}
end
