defmodule Rivet.Auth.Graphql do
  @moduledoc """
  Helpers for Graphql resolvers.
  """
  import Rivet.Graphql
  alias Rivet.Auth
  alias Rivet.Ident
  alias Absinthe.Resolution

  ##############################################################################
  @doc """
  Handles extracting the current user from the Absinthe context, and then will
  either call `func` and pass in the current user or return an error if there is
  no user in the context
  """
  def current_user(%Resolution{context: %{user: %{} = u}}),
    do: {:ok, u}

  def current_user(_), do: {:error, :authn}

  def current_user(%Resolution{context: %{user: %{} = user}}, method) do
    if not is_nil(method) do
      graphql_log(method)
    end

    {:ok, user}
  end

  def current_user(_, method), do: graphql_error(method, :authn)

  ########################################################################
  @doc """
  Accept authorization from a user.
  Punt to authz_action(), but log graphql bits.
  """
  def authz_user(
        context,
        assertion \\ %Auth.Assertion{action: :system_admin},
        method \\ nil,
        kwlog \\ []
      )

  def authz_user(info, assertion, method, kwlog) do
    with {:ok, user} <- Rivet.Auth.check_authz(info, assertion) do
      graphql_log(method, kwlog)
      {:ok, user}
    else
      _ ->
        graphql_error(method, :authz)
    end
  end

  ##############################################################################
  @doc """
  check_authz/2 attempts to verify %Auth.Assertion{} against the specified user,
  and if the assertion includes a domain reference, it will attempt to walk
  up the reference tree (if a parent_id exists) and try checking auth again.
  """
  def check_authz(%{context: %{user: %Ident.User{} = u}}, assertion),
    do: check_authz(u, assertion)

  def check_authz(%Ident.User{} = user, %Auth.Assertion{domain: :global} = assertion) do
    Ident.User.Lib.check_authz(user, assertion)
  end

  def check_authz(%Ident.User{} = user, %Auth.Assertion{domain: domain} = assertion) do
    with {:error, user} <- Ident.User.Lib.check_authz(user, assertion),
         {:ok, %{parent_id: parent_id}} when is_binary(parent_id) <-
           domain.one(id: assertion.ref_id) do
      # walk up the tree, but disable fallback -- if it didn't work before,
      # it won't work again
      check_authz(user, %Auth.Assertion{assertion | fallback: false})
    else
      {:ok, %Ident.User{}} = pass -> pass
      _ -> {:error, user}
    end
  end

  def check_authz(_, _), do: {:error, nil}

  ##############################################################################
  @doc """
  This wraps check_authz with logging and creates normal error output for
  Absinthe to handle.

      with {:ok, authed} <- authz(context, %Rivet.Auth.Assertion{}, "doTheThing") do
        handle success
      end
  """
  @type az_user :: Ident.User.t() | map()
  @type az_assertion :: Auth.Assertion.t()
  @type az_log :: String.t() | nil
  @spec authz(az_user, az_assertion, az_log) ::
          {:ok, Ident.User.t()} | {:ok, map()}

  def authz(meta, assertion, log \\ nil, kwlog \\ [])
  def authz(meta, assertion, nil, _), do: check_authz(meta, assertion)

  def authz(meta, assertion, log, kwlog) do
    with {:ok, user} <- check_authz(meta, assertion) do
      graphql_log(log, kwlog)
      {:ok, user}
    else
      _ ->
        graphql_error(log, :authz)
    end
  end

  @spec action(atom(), keyword()) :: Auth.Assertion.t()
  def action(a, opts \\ []), do: struct(Auth.Assertion, opts ++ [action: a])
end
