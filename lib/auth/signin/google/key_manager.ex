defmodule Rivet.Auth.Signin.Google.KeyManager do
  @moduledoc """
  This module runs as a separate process which keeps google's oauth public certs
  current, as they change weekly.  This process inspects the expiration date
  (which google says should be correct) and updates at least by then, but does
  not wait longer than 1 day.
  """

  require Logger
  use GenServer

  @certs_url ~c"https://www.googleapis.com/oauth2/v1/certs"

  @request_timeout 500
  @max_refresh_seconds 86_400
  @min_refresh_seconds 300
  @refresh_buffer_seconds 300
  @retry_seconds 60

  ##############################################################################
  ### genserver stuff
  def start_link(_opts),
    do: GenServer.start_link(__MODULE__, :ok, name: :google_cert_manager)

  @impl GenServer
  def init(:ok), do: {:ok, %{certs: %{}}, {:continue, :refresh}}

  @impl GenServer
  def handle_continue(:refresh, state), do: refresh(state)

  @impl GenServer
  def handle_info(:refresh, state), do: refresh(state)

  @impl GenServer
  def handle_call(:get_certs, _from, %{certs: certs} = state), do: {:reply, certs, state}

  ##############################################################################
  @doc """
  External interface to request a current copy of the certs for google

  ```
  iex> dict = Rivet.Auth.Signin.Google.KeyManager.get_certs()
  iex> is_map(dict)
  true
  ```
  """
  def get_certs(), do: GenServer.call(:google_cert_manager, :get_certs)

  ##############################################################################
  defp refresh(state) do
    Logger.info("Refreshing Google Auth Certificates")

    # its always {:ok,..} because this converts {:error,..} to a log
    {:ok, wait_seconds, certs} = refresh_certs_and_requeue(state.certs)

    Process.send_after(self(), :refresh, wait_seconds * 1_000)

    {:noreply, %{state | certs: certs}}
  end

  defp refresh_certs_and_requeue(old_certs) do
    with {:error, msg} <- fetch_certificates!() do
      Logger.error("Refreshing Google Auth Certificates Failure: #{msg}")
      {:ok, @retry_seconds, old_certs}
    end
  end

  defp fetch_certificates!() do
    # doing it with clunky erlang :httpc avoids a dependency on hackney
    :httpc.request(:get, {@certs_url, []}, [timeout: @request_timeout], body_format: :binary)
    |> case do
      {:ok, {{_version, 200, _reason}, headers, body}} ->
        # possibly we could verify application/json in headers but eh -BJG
        {:ok, next_refresh!(headers), decode_certs!(body)}

      {:ok, _result} ->
        # IO.inspect(result, label: "Invalid result from google certs query")
        {:error, "Invalid HTTP result from google certs query"}

      {:error, _} = pass ->
        pass
    end
  end

  defp decode_certs!(raw_json) do
    Jason.decode!(raw_json)
    |> Map.new(fn {cert_id, pem} -> {cert_id, JOSE.JWK.from_pem(pem)} end)
  end

  defp get_header(headers, wanted_name) do
    #
    # :httpc returns
    #
    #   field :: charlist()
    #   value :: binary() | iolist()
    #
    Enum.find_value(headers, fn {field, value} ->
      if String.downcase(List.to_string(field)) == wanted_name,
        do: {:ok, IO.iodata_to_binary(value)}
    end)
  end

  # Refresh timing
  defp next_refresh!(headers) do
    with {:ok, expires} <- get_header(headers, "expires"),
         {:ok, expires_at} <- parse_rfc1123_datetime(expires) do
      expires_in = DateTime.to_unix(expires_at) - System.system_time(:second)

      if expires_in > @max_refresh_seconds do
        @max_refresh_seconds
      else
        max(
          expires_in - @refresh_buffer_seconds,
          @min_refresh_seconds
        )
      end
    else
      _ ->
        Logger.error("Google certificate response has no valid Expires header")
        Logger.error("Response headers: #{inspect(headers)}")

        @retry_seconds
    end
  end

  def parse_rfc1123_datetime(value) do
    with erl_date when erl_date != :bad_date <-
           :httpd_util.convert_request_date(String.to_charlist(value)),
         {:ok, naive} <- NaiveDateTime.from_erl(erl_date),
         {:ok, datetime} <- DateTime.from_naive(naive, "Etc/UTC") do
      {:ok, datetime}
    else
      _ -> :error
    end
  end
end
