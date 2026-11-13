defmodule Rivet.Auth.Assertion do
  @moduledoc """
  Used for standardizing auth assertion checks.

  Passed in when declaring what type of auth is needed
  """
  alias __MODULE__

  use Rivet.Ident
  import Rivet.Graphql

  defstruct action: :none,
            domain: :global,
            app: nil,
            ref_id: nil,
            fallback: false

  @type t :: %Assertion{
          action: atom(),
          # if CXS app auth allowed, match this app
          app: nil | atom(),
          domain: atom(),
          # item.id of item defined by domain
          ref_id: nil | String.t(),
          # if key above doesn't work, should we check global privs?
          fallback: boolean()
        }

  def action(a, opts \\ []), do: struct(Assertion, opts ++ [action: a])

  ##############################################################################
  @doc """

  check/2 attempts to verify %Assertion{} against the specified user,
  and if the assertion includes a domain reference and fallback is true,
  it will attempt a :global domain of the same permission (this is for superadmin
  rights to certain things).

  """

  def check_authz(%User{} = u, %Assertion{} = a, opts \\ []),
    do: check_authz_(u, a, opts)

  ####
  defp check_authz_(user, %{action, domain: :global}, opts) do
    with {:ok, user} <- Rivet.Auth.Cache.get_authz(user, opts),
         do: check_domain_(user, action, :global, nil)
  end

  defp check_authz_(user, %{action, domain, ref_id, fallback}, opts) do
    with {:ok, user} <- Rivet.Auth.Cache.get_authz(user, opts),
         {:error, user} <- check_domain_(user, action, domain, ref_id) do
      if fallback,
        do: check_domain_(user, action, :global, nil),
        else: {:error, user}
    end
  end

  ##############################################################################
  defp check_domain_(user, action, domain, ref_id) do
    if MapSet.member?(user.authz, {action, domain, ref_id}),
      do: {:ok, user},
      else: {:error, user}
  end

  ##############################################################################
  def web_check_authz(user, assertion, method \\ nil, kwlog \\ []) do
    with {:ok, user} <- check_authz(user, assertion) do
      graphql_log(method, kwlog)
      {:ok, user}
    else
      _ ->
        graphql_error(method, :authz)
    end
  end
end
