defmodule Rivet.Auth.Web.Controller do
  @moduledoc """

  Used alongside Rivet.Auth.Web.Plug

  NOTE: options() is usually handled by another plug.. forgot which though

  ```
  scope "/authx/v1/api" do
    pipe_through([:base_web, :browser])

    post("/signon", WebSvc.Controllers.Auth, :signon)
    post("/refresh", WebSvc.Controllers.Auth, :refresh)
    get("/signout", WebSvc.Controllers.Auth, :signout)
    post("/signout", WebSvc.Controllers.Auth, :signout)
    get("/access", WebSvc.Controllers.Auth, :access)
    post("/identify", WebSvc.Controllers.Auth, :access)
  end
  ```

  """

  use WebSvc, :controller
  require Logger
  use Rivet.Ident
  alias Rivet.Auth.Signin
  import Rivet.Graphql, only: [error_string: 1]

  @initial_user_type :authed

  @throttle :auth
  @limit_window 60_000
  @limit_max 10

  def rate_limit(conn, func, throttle \\ @throttle, window \\ @limit_window, max \\ @limit_max) do
    remote = Web.Connection.get_remote(conn)

    case Web.Throttle2.check_throttle(remote, throttle, window, max) do
      :stop -> send_resp(conn, 429, "")
      :cont -> func.(remote)
    end
  end

  def signon(conn, params) do
    with {:ok, site} <- Web.Connection.get_site_403(conn),
         do: signon(conn, site, params) |> after_signon(conn)
  end

  # GOOGLE - returning user
  def signon(_conn, site, params = %{"type" => "google"}),
    do: Signin.Google.check(site, params, @initial_user_type)

  # LOCAL - new user
  def signon(_conn, site, params = %{"signup" => true}),
    do: Signin.Local.signup(site, params, @initial_user_type)

  # LOCAL - returning user
  def signon(_conn, site, params = %{"signup" => false}),
    do: Signin.Local.check(site, params)

  # ERROR
  def signon(conn, _site, params) do
    Logger.info("Failed to match a condition with these payload keys.", keys: Map.keys(params))

    send_failure(
      conn,
      "Input parameters don't match any condition we can use!",
      "Unable to Sign in"
    )
  end

  ##############################################################################
  # after_signon is a pipeline grouping of other post-signin methods,
  # so the various signin function above don't have to have extra imperative
  # logic for their contexts.  Although each function is called below, the function
  # should only enrich or after_signon if it's context matches
  defp after_signon({:ok, %Auth.Domain{site: %Db.Site{}} = auth}, conn) do
    {:ok, auth, conn}
    |> create_validation_factor(:acc)
    |> set_user_auth_type
    |> update_conn
  end

  # If we have a user message, then make it a different type of failure
  defp after_signon({:error, %Auth.Domain{error: error, log: failure}}, conn)
       when is_binary(error) do
    if is_binary(failure) and String.length(failure) > 0 do
      Logger.info(failure)
    end

    conn
    |> put_status(200)
    |> json(%{signin: false, reason: error})
  end

  defp after_signon({:error, %Auth.Domain{error: error, log: failure}}, conn),
    do: send_failure(conn, failure, error)

  defp after_signon({:error, pwd_err}, conn),
    do: send_failure(conn, pwd_err, pwd_err)

  ##############################################################################
  defp set_user_auth_type({:ok, %Auth.Domain{user: %Db.Ident.User{type: :authed}}, _} = pass),
    do: pass

  defp set_user_auth_type({:ok, %Auth.Domain{user: %Db.Ident.User{type} = user} = auth, conn})
       when type in [:identity, :archived] do
    {:ok, user} = Db.Ident.User.update(user, %{type: :authed})
    {:ok, %Auth.Domain{auth | user: user}, conn}
  end

  defp set_user_auth_type({:ok, %Auth.Domain{user: %Db.Ident.User{type: :unknown}}, _}) do
    {:error, "unexpectedly received user with type: unknown"}
  end

  #
  # defp set_user_auth_type({:error, _} = pass),
  #   do: pass

  ##############################################################################
  @doc """
  Validate the refresh token sent by the client and returns an access token
  """
  def refresh(conn, params) do
    with {:ok, site} <- Web.Connection.get_site(conn),
         {:ok, %Auth.Domain{status: :authed}, %Auth.Domain{status: :authed, factor: factor}} <-
           Codex.Auth.Refresh.assure(%Auth.Domain{site: site, hostname: site.domain}, params),
         {:ok, token, _} <- Codex.Auth.Token.Access.jwt(factor, site.domain) do
      Db.Ident.User.Lib.user_seen(factor.user, site)
      Logger.info("Refreshed Access Token")
      json(conn, %{access_token: token})
    else
      {:error, %Auth.Domain{} = d} ->
        send_failure(conn, d)

      {:error, msg} ->
        send_failure(conn, msg, "Unable to Refresh")
    end
  end

  ##############################################################################
  defp create_validation_factor(
         {:ok, %Auth.Domain{user: %Db.Ident.User{}, hostname: hostname} = auth, conn},
         _type
       ) do
    with {:ok, token} <- Codex.Auth.Token.Validation.key(hostname, auth.user) do
      {:ok, %Auth.Domain{auth | token: token}, conn}
    else
      err ->
        {:error, %Auth.Domain{auth | log: "Unable to create validaton token #{inspect(err)}"},
         conn}
    end
  end

  defp create_validation_factor({:ok, %Auth.Domain{}, _conn} = pass, _), do: pass

  ##############################################################################
  defp update_conn({:ok, %Auth.Domain{status: :authed} = auth, conn}) do
    case Web.Auth.did_signin(conn, auth) do
      response ->
        Logger.info("Valid User Signon", uid: auth.user.id)
        json(response, auth.token)
    end
  end

  defp update_conn({_, %Auth.Domain{log: failure, error: error}, conn}),
    do: send_failure(conn, failure, error)

  ##############################################################################
  def send_failure(conn, %Auth.Domain{log: failure, error: error}),
    do: send_failure(conn, failure, error)

  def send_failure(conn, failure, error) when is_binary(failure) do
    if String.length(failure) > 0 do
      Logger.error(failure)
    end

    error =
      if not is_nil(error) and String.length(error) > 0 do
        error
      else
        :authn
      end

    conn
    |> put_status(200)
    |> json(%{signin: false, reason: error})
  end

  def send_failure(conn, failure, error),
    do: send_failure(conn, error_string(failure), error_string(error))

  @doc """
  dummy endpoint to deal with OPTIONS preflight CORS requests
  """
  def options(conn, _params) do
    send_resp(conn, :no_content, "")
  end

  @doc """
  endpoint for validating access tokens
  """
  def access(conn = %Plug.Conn{assigns: %{user: %Db.Ident.User{}}}, _params) do
    rate_limit(conn, fn _ -> conn |> send_resp(:no_content, "") end)
  end

  def access(conn = %Plug.Conn{assigns: %{app: app}}, _params) when not is_nil(app) do
    rate_limit(conn, fn _ -> conn |> send_resp(:no_content, "") end)
  end

  def access(conn, _params) do
    rate_limit(conn, fn _ -> conn |> send_resp(403, "not authorized") end)
  end

  @doc """
  """
  def signout(conn, _params) do
    Web.Auth.did_signout(conn)
    |> send_resp(:no_content, "")
  catch
    x, err ->
      Logger.error(Exception.format(:error, err, __STACKTRACE__))
      IO.inspect({x, err}, label: "STACK TRACE IN #{__MODULE__}.update_owner")
      :error
  end

  ##############################################################################
  # defp rate_limited(conn, reason, remote_ip, {code, msg} \\ {429, "too many requests"}) do
  #   Logger.warning("rate limit", endpoint: "authx/identify", remote_ip: remote_ip, reason: reason)
  #   conn |> send_resp(code, msg)
  # end

  defp identify_email(conn, _eaddr, _remote, args) do
    with {:ok, site} <- Web.Connection.get_site(conn),
         {:ok, _} <- Codex.Auth.Identify.identify(site, Transmogrify.transmogrify(args)) do
      conn
      |> send_resp(:no_content, "")
    else
      {:error, %Auth.Domain{error: errmsg}} ->
        Logger.warning(errmsg)
        conn |> send_resp(406, errmsg)

      {:error, str} ->
        Logger.error(str)
        {:error, "Unable to continue"}

      {:hit, _} ->
        Logger.warning("email address already exists")
        conn |> send_resp(429, "")
    end
  end

  def identify(conn, %{"email" => eaddr} = args) do
    rate_limit(conn, fn remote -> identify_email(conn, eaddr, remote, args) end)
  end
end
