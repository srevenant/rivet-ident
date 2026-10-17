defmodule Rivet.Auth do
  @moduledoc """
  Public interface to authentication and authorization functions.
  """
  import Rivet.Graphql
  alias Rivet.Auth.Assertion
  alias Rivet.Auth.Signin
  use Rivet.Ident
  require Logger

  @doc """
  check_authz/2 attempts to verify %Assertion{} against the specified user,
  and if the assertion includes a domain reference, it will attempt to walk
  up the reference tree (if a parent_id exists) and try checking auth again.
  """

  def check_authz(u, a, opts \\ [])

  def check_authz(%User{} = u, %Assertion{} = a, opts),
    do: check_authz_(u, a, opts)

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

  ########
  defp check_authz_(user, %{action, domain: :global}, opts) do
    with {:ok, user} <- Rivet.Auth.Cache.get_authz(user, opts),
         do: domain_authz(user, action, :global, nil)
  end

  defp check_authz_(user, %{action, domain, ref_id, fallback}, opts) do
    with {:ok, user} <- Rivet.Auth.Cache.get_authz(user, opts),
         {:error, user} <- domain_authz(user, action, domain, ref_id) do
      if fallback,
        do: domain_authz(user, action, :global, nil),
        else: {:error, user}
    end
  end

  ########
  defp domain_authz(user, action, domain, ref_id) do
    if MapSet.member?(user.authz, {action, domain, ref_id}),
      do: {:ok, user},
      else: {:error, user}
  end

  ######## old User.check_authz
  # @spec check_authz(user :: User.t(), Assertion.t()) ::
  #         {:ok | :error, User.t()}
  # def check_authz(user, %Assertion{} = assertion) do
  #   key = {assertion.action, assertion.domain, assertion.ref_id}
  #   user = User.Lib.get_authz(user)
  #
  #   if MapSet.member?(user.authz, key) do
  #     {:ok, user}
  #   else
  #     if assertion.fallback and MapSet.member?(user.authz, {assertion.action, :global, nil}) do
  #       {:ok, user}
  #     else
  #       {:error, user}
  #     end
  #   end
  # end
  #
  ######### old Auth.check_authz
  # def check_authz(%{context: %{user: %Ident.User{} = u}}, assertion),
  #   do: check_authz(u, assertion)
  #
  # def check_authz(%Ident.User{} = user, %Assertion{domain: :global} = assertion) do
  #   Ident.User.Lib.check_authz(user, assertion)
  # end
  #
  # def check_authz(%Ident.User{} = user, %Assertion{domain: domain} = assertion) do
  #   with {:error, user} <- Ident.User.Lib.check_authz(user, assertion),
  #        {:ok, %{parent_id: parent_id}} when is_binary(parent_id) <-
  #          domain.one(id: assertion.ref_id) do
  #     # Walk up the tree, but disable fallback. If it didn't work before, it
  #     # won't work again.
  #     check_authz(user, %{assertion | fallback: false})
  #   else
  #     {:ok, %Ident.User{}} = pass -> pass
  #     _ -> {:error, user}
  #   end
  # end
  #
  # def check_authz(_, _), do: {:error, nil}

  @spec change_password(Ident.User.Code.t(), String.t()) :: boolean()
  def change_password(%Ident.User.Code{} = code, new), do: set_password(code.user, new)

  @spec change_password(Ident.User.t(), String.t(), String.t()) :: boolean()
  def change_password(%Ident.User{} = user, current, new) do
    if Signin.Local.check_password(user, current) do
      set_password(user, new)
    else
      Logger.warning("password change failure: current password mis-match", user_id: user.id)

      false
    end
  end

  @spec set_password(Ident.User.t(), String.t()) :: boolean()
  defp set_password(%Ident.User{} = user, new) do
    case Ident.Factor.Lib.set_password(user, new) do
      {:ok, %Ident.Factor{}} ->
        Rivet.Ident.mailer_template(:password_changed).queue(user)
        true

      error ->
        IO.inspect(error, label: "password change error")

        Logger.error("password change failure: cannot set factor", user_id: user.id)

        false
    end
  end

  def authz_action(user, assertion, method \\ nil, kwlog \\ []) do
    with {:ok, user} <- check_authz(user, assertion) do
      graphql_log(method, kwlog)
      {:ok, user}
    else
      _ ->
        graphql_error(method, :authz)
    end
  end
end
