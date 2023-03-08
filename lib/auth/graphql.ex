defmodule Rivet.Auth.Graphql do
  @moduledoc """
  Helpers for Graphql resolvers.
  """
  import Rivet.Graphql
  alias Rivet.Auth
  alias Rivet.Ident

  def current_user(info, method \\ nil)

  def current_user(%{context: %{user: %Ident.User{} = u}}, method) do
    graphql_log(method)

    {:ok, u}
  end

  def current_user(_, method), do: graphql_error(method, :authn)

  def with_current_user(info, method, good_func \\ nil, bad_func \\ nil)

  def with_current_user(
        %{context: %{user: %Ident.User{} = user}},
        method,
        good,
        _
      )
      when is_function(good) do
    graphql_log(method)
    good.(user)
  end

  def with_current_user(_, method, _good, bad) when is_function(bad) do
    graphql_log(method)
    bad.(nil)
  end

  def with_current_user(_, method, _, _), do: graphql_error(method, :authn)

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
