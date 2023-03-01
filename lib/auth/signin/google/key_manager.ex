defmodule Rivet.Auth.Signin.Google.AuthKeys do
  @moduledoc """
  Syntactic sugar to wrap the HTTP call in requesting the keys.  Questionable
  if this is worthwhile, but it's working now...
  """
  def get!(path) do
    {:ok, 200, headers, body} =
      :hackney.request(:get, "https://www.googleapis.com/oauth2/v1/#{path}", [], "",
        ssl_options: [
          versions: [:"tlsv1.2"],
          # HTTPoison default_ssl_options()
          verify: :verify_peer,
          cacertfile: :certifi.cacertfile(),
          depth: 10,
          customize_hostname_check: [
            match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
          ]
        ],
        recv_timeout: 500,
        with_body: true
      )

    %{headers: headers, body: Jason.decode!(body)}
  end
end

defmodule Rivet.Auth.Signin.Google.KeyManager do
  @moduledoc """
  This module runs as a separate process which keeps google's oauth public keys
  current, as they change weekly.  This process inspects the expiration date
  (which google says should be correct) and updates at least by then, but does
  not wait longer than 1 day.
  """
  require Logger
  use GenServer

  ##############################################################################
  # Google Manager service logic

  @doc """
  External interface to request a current copy of the keys for google

  iex> dict = Rivet.Auth.Signin.Google.KeyManager.get_keys()
  iex> is_map(dict)
  true
  """
  def get_keys() do
    GenServer.call(:google_key_manager, :get_keys)
  end

  # Internal method that handles calling Google to get current keys, based on
  # an interval derived from the google request expires header (this is their
  # recommendation)
  defp run_interval(state) do
    Logger.info("Refreshing Google Auth Certificates")
    result = Rivet.Auth.Signin.Google.AuthKeys.get!("certs")
    now_t = System.os_time(:second)

    exp_t =
      case Enum.find(result.headers, fn {k, _} -> String.downcase(k) == "expires" end) do
        {_, expires} ->
          Timex.parse!(expires, "{RFC1123}") |> Timex.to_unix()

        nil ->
          Logger.error("Unexpected: google auth did not respond with an expires")
          Logger.error("Response Headers: #{inspect(result.headers)}")
          # giving a 1-min expiration will force a recheck in 1 min
          now_t + 60
      end

    # give ourselves a buffer, with some imperative assertions...
    diff_t = exp_t - now_t
    # greater than a day?  Just refresh it in a day
    interval =
      if diff_t > 86400 do
        86400
      else
        # wow, it expires today! worst case, refresh in five mins, unless that is too far?
        if diff_t - 300 <= 0 do
          300
        else
          # trim off 5 mins
          diff_t - 300
        end
      end

    # update the interval
    state = Map.put(state, :interval, interval * 1000)

    # update the key set
    Map.put(state, :keys, result.body |> decode_keys)
  end

  # NOTE: try using JOSE's JWK instead of the PEM one
  # Internal method to convert the keys from PEM format into what we are using.
  #
  # Google also provides a JSON format other than this PEM, but we are having
  # problems getting it to work w/JOSE.  The PEM works.
  defp decode_keys(keys) do
    Enum.reduce(keys, %{}, fn {k, v}, acc ->
      Map.put(acc, k, JOSE.JWK.from_pem(v))
    end)
  end

  ##############################################################################
  # general GenServer things after this

  # standard way for us to request a future interval callback
  defp queue_interval(interval) do
    Process.send_after(:google_key_manager, :interval, interval)
  end

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: :google_key_manager)
  end

  def init(state) do
    Map.merge(state, %{interval: 60_000, keys: %{}})
    queue_interval(0)
    {:ok, state}
  end

  def handle_info(:interval, state = %{interval: _interval}) do
    state = %{interval: interval} = run_interval(state)
    queue_interval(interval)
    {:noreply, state}
  end

  def handle_call(:get_keys, _from, state = %{keys: keys}) do
    {:reply, keys, state}
  end
end
