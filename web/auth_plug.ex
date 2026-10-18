defmodule Rivet.Auth.Web.Plug do
  @moduledoc """
  used alongside Rivet.Auth.Web.Controller

  ```
  pipeline ... do
    plug(Rivet.Auth.Web.Plug)
    ...
  end
  ```

  """

  defmacro __using__(_) do
    quote location: :keep do
      use Rivet.Ident
      alias Rivet.Auth
      alias Rivet.Auth.Web

      @behaviour Plug

      @impl true
      def init(opts), do: opts

      @impl true
      def call(conn, _args), do: check_access(conn) |> Web.Session.update_session(conn)

      #####
      defp check_access(conn) do
        with {:ok, auth} <- initial_auth_domain(conn),
             do: Auth.Access.check(Plug.Conn.get_req_header(conn, "authorization"), auth)
      end

      #####
      defp initial_auth_domain(conn) do
        with {:ok, site} <- Rivet.Auth.Web.Plug.get_target(conn),
             do: {:ok, %Auth.Domain{hostname: site.domain, site: site}}
      end

      def get_target(%Plug.Conn{host} = conn) when not_empty_str(host), do: {:ok, host}
      def get_target(_), do: {:error, "Cannot identify target server name"}
    end
  end
end
