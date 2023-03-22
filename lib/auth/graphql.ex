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
  def current_user(%Resolution{context: %{user: %Ident.User{} = u}}),
    do: {:ok, u}

  def current_user(_), do: {:error, :authn}

  def current_user(%Resolution{context: %{user: %Ident.User{} = user}}, method) do
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
    with {:ok, user} <-
           Rivet.Auth.check_authz(info, assertion) do
      graphql_log(method, kwlog)
      {:ok, user}
    else
      _ ->
        graphql_error(method, :authz)
    end
  end
end
