defmodule Rivet.Auth.Web do
  @moduledoc """
  Helpers for Web services and GraphQL resolvers.
  """
  import Rivet.Graphql
  alias Rivet.Auth
  use Rivet.Ident
  alias Absinthe.Resolution

  ##############################################################################
  @doc """

  Handles extracting the current user from the Absinthe context, and then will
  either call `func` and pass in the current user or return an error if there is
  no user in the context

  ```
  iex> {:error, :authn} = current_user(nil)
  ```

  """
  def current_user(%Resolution{context: %{user: %User{} = u}}),
    do: {:ok, u}

  def current_user(_), do: {:error, :authn}

  def current_user(%Resolution{context: %{user: %User{} = u}}, method) do
    if not is_nil(method), do: graphql_log(method)
    {:ok, u}
  end

  def current_user(_, method), do: graphql_error(method, :authn)

  @doc """

  ```
  iex> {:ok, nil} = optional_user(nil, "test")
  ```

  """
  def optional_user(%{context: %{user: %User{} = user}}, method) do
    graphql_log(method)
    {:ok, user}
  end

  def optional_user(_, method) do
    graphql_log(method)
    {:ok, nil}
  end

  ###############
  def mine_or_public(target_id, info) do
    with {:ok, user} <- current_user(info) do
      user = if target_id == user.id, do: user, else: :public
      {:ok, user}
    end
  end

  # ########################################################################
  # @doc """
  # Accept authorization from a user.
  # Punt to authz_action(), but log graphql bits.
  # """
  # def authz_user(
  #       context,
  #       assertion \\ %Auth.Assertion{action: :system_admin},
  #       method \\ nil,
  #       kwlog \\ []
  #     )
  #
  # def authz_user(info, assertion, method, kwlog) do
  #   with {:ok, user} <- Rivet.Auth.check_authz(info, assertion) do
  #     graphql_log(method, kwlog)
  #     {:ok, user}
  #   else
  #     _ ->
  #       graphql_error(method, :authz)
  #   end
  # end

  ##############################################################################
  @doc """
  check_authz/2 attempts to verify %Auth.Assertion{} against the specified user,
  and if the assertion includes a domain reference, it will attempt to walk
  up the reference tree (if a parent_id exists) and try checking auth again.
  """
  # @spec
  def check_authz(%{context: %{user: %User{} = u}}, assertion),
    do: check_authz(u, assertion)

  def check_authz(%User{} = user, %Auth.Assertion{domain: :global} = assertion),
    do: Rivet.Auth.check_authz(user, assertion)

  def check_authz(%User{} = user, %Auth.Assertion{domain: domain} = assertion) do
    with {:error, user} <- Rivet.Auth.check_authz(user, assertion),
         {:ok, %{parent_id: parent_id}} when is_binary(parent_id) <-
           domain.one(id: assertion.ref_id) do
      # walk up the tree, but disable fallback -- if it didn't work before,
      # it won't work again
      check_authz(user, %Auth.Assertion{assertion | fallback: false})
    else
      {:ok, %User{}} = pass -> pass
      _ -> {:error, user}
    end
  end

  def check_authz(_, _), do: {:error, nil}

  ##############################################################################
  @doc """
  This wraps check_authz with logging and creates normal error output for
  Absinthe to handle.

  ```
  with {:ok, authed} <- web_authz(context, %Rivet.Auth.Assertion{}, "doTheThing") do
    handle success
  end
  ```
  """
  # @type az_user :: User.t() | map()
  # @type az_assertion :: Auth.Assertion.t()
  # @type az_log :: String.t() | nil
  # @spec web_authz(az_user, az_assertion, az_log) ::
  #         {:ok, User.t()} | {:ok, map()}
  #
  def web_authz(meta, assertion, log \\ nil, kwlog \\ [])
  def web_authz(meta, assertion, nil, _), do: check_authz(meta, assertion)

  def web_authz(meta, assertion, log, kwlog) do
    with {:ok, user} <- check_authz(meta, assertion) do
      graphql_log(log, kwlog)
      {:ok, user}
    else
      _ ->
        graphql_error(log, :authz)
    end
  end

  @doc """
  Calling with graphql metadata; separate pattern match to be explicit and also
  handle the authn condition
  """
  def web_check_authz(a, b, opts \\ [])

  def web_check_authz(%{context}, %Assertion{} = a, opts) do
    # split in two parts for better logging
    case context do
      %{user: %User{} = u} -> check_authz_(u, a, opts)
      _ -> {:error, :authn}
    end
  end

  # not authenticated
  def web_check_authz(%User{} = u, %Assertion{} = a, opts),
    do: check_authz_(u, a, opts)

  # this is a code prob most likely
  def web_check_authz(_, _, _) do
    Rivet.Ident.critical_report("web_check_authz received bad args?")
    {:error, :authn}
  end
end
