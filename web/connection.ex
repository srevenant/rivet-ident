defmodule Rivet.Auth.Web.Connection do
  import Plug.Conn
  import Core.Guards

  def get_target(%Plug.Conn{} = conn) do
    case conn do
      %Plug.Conn{host: host} when not_empty_str(host) -> {:ok, host}
      _ -> {:error, "Cannot identify target host"}
    end
  end

  ##############################################################################
  def get_remote(conn) do
    # remove the stupidity of erlang IP tuples
    ip = ip_as_str(conn.remote_ip)

    Logger.metadata(remote: ip)

    ip
  end

  defp ip_as_str(x) when is_binary(x), do: x
  defp ip_as_str(x) when is_tuple(x), do: :inet.ntoa(x) |> to_string()

  ##############################################################################
  def get_site(%Plug.Conn{} = conn) do
    with {:ok, name} <- get_target(conn), do: Core.Cache.Site.get(name)
  end

  def get_site_403(conn) do
    case get_site(conn) do
      {:error, _} -> put_status(conn, 403)
      {:ok, _} = pass -> pass
    end
  end
end
