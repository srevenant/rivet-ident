defmodule Rivet.Auth do
  @moduledoc """
  Public interface to authentication and authorization functions.
  """
  import Rivet.Graphql
  alias Rivet.Auth.Assertion
  alias Rivet.Auth.Signin
  alias Rivet.Ident
  require Logger

  def check_authz(%{context: %{user: %Ident.User{} = u}}, assertion),
    do: check_authz(u, assertion)

  def check_authz(%Ident.User{} = user, %Assertion{domain: :global} = assertion) do
    Ident.User.Lib.check_authz(user, assertion)
  end

  def check_authz(%Ident.User{} = user, %Assertion{domain: domain} = assertion) do
    with {:error, user} <- Ident.User.Lib.check_authz(user, assertion),
         {:ok, %{parent_id: parent_id}} when is_binary(parent_id) <-
           domain.one(id: assertion.ref_id) do
      # Walk up the tree, but disable fallback. If it didn't work before, it
      # won't work again.
      check_authz(user, %{assertion | fallback: false})
    else
      {:ok, %Ident.User{}} = pass -> pass
      _ -> {:error, user}
    end
  end

  def check_authz(_, _), do: {:error, nil}

  @spec change_password(Ident.UserCode.t(), String.t()) :: boolean()
  def change_password(%Ident.UserCode{} = code, new), do: set_password(code.user, new)

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
        Ident.User.Notify.PasswordChanged.send(user)
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
