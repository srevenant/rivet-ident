defmodule Rivet.Auth.Web.Session do
  use Rivet.Ident

  @doc """
  Convenience wrapper that extracts user
  """
  def did_signin(conn, %Auth.Domain{status: :authed, user: %Ident.User{}} = auth),
    do: set_session_authn(conn, auth)

  def did_signin(conn, _auth) do
    Logger.error("Unexpected auth error: Parameters for did_signin are not correct")
    did_signout(conn)
  end

  def did_signout(conn), do: set_session_authn(conn, %Auth.Domain{})

  ##############################################################################
  # signed in
  def update_session({:ok, %Auth.Domain{status: :authed, user: %Ident.User{}} = auth}, c),
    do: set_session_authn(c, auth)

  # not signed in
  def update_session({:missing, auth}, c),
    do: set_session_authn(c, auth)

  # other errors
  def update_session({:error, %Auth.Domain{} = auth}, c) do
    log_error(auth.log)
    set_session_authn(c, auth)
  end

  def update_session({:error, msg}, c) do
    log_error(msg)
    set_session_authn(c, %Auth.Domain{})
  end

  defp log_error(msg) when not_empty_str(msg), do: Logger.error(msg)

  # coveralls-ignore-next-line
  defp log_error(_), do: :ok

  ##############################################################################
  # # /3
  # def set_session_authn(conn, user, %Auth.Domain{hostname: hostname} = auth),
  #   do: set_session_authn(conn, user, auth, hostname)
  #
  # def set_session_authn(conn, user, nil),
  #   do: set_session_authn(conn, user, %Auth.Domain{}, nil)

  # /4
  # def set_session_authn(conn, user, nil, hostname),
  #   do: set_session_authn(conn, user, %Auth.Domain{}, hostname)

  defp set_session_authn(conn, %Auth.Domain{user, hostname, site} = auth) do
    conn
    |> put_session(:hostname, hostname)
    |> assign(:user, user)
    |> assign(:auth, auth)
    |> Absinthe.Plug.put_options(
      context: %{
        user: user,
        site: site,
        remote: Web.Connection.get_remote(conn)
      }
    )
  end
end
