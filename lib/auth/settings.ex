defmodule Rivet.Auth.Settings do
  @moduledoc """
  How we are configured globally
  """
  require Logger
  import Rivet.Utils.Types, only: [as_atom: 1]

  ###########################################################################
  def secret_keys(:val), do: getcfg(:jwt_val_secrets_decoded, [])
  def secret_keys(_), do: getcfg(:jwt_acc_secrets_decoded, [])

  @doc """
  Called by Application.start, to configure the runtime state from other sources
  """
  def decode_secrets(source) do
    key = as_atom("jwt_#{source}_secrets")

    putcfg(
      Enum.map(getcfg(key, []), fn x ->
        Base.decode64!(x)
      end),
      as_atom("#{key}_decoded")
    )
  end

  def start() do
    decode_secrets(:acc)
    decode_secrets(:val)
    getcfg(:federated, %{}) |> to_map |> putcfg(:federated)
    %{} |> putcfg(:client)
  end

  ###########################################################################
  @doc """
  Get the most current secret based on token type(:acc, :val etc..), for jwt hashes
  """
  def current_jwt_secret(token_type) do
    case secret_keys(token_type) do
      [secret | _rest] -> secret
      _ -> raise ArgumentError, "Missing configuration as array: auth:jwt_acc_secrets?"
    end
  end

  ###########################################################################

  def expire_limit(token_type, sub_type \\ nil)

  def expire_limit(token_type, nil) do
    case getcfg(:auth_expire_limits, %{})[token_type] do
      dict when is_map(dict) ->
        raise "Invalid expire limit request for key #{inspect(token_type)} with no subkey"

      value ->
        value
    end
  end

  def expire_limit(token_type, sub_type) when is_binary(sub_type),
    do: expire_limit(token_type, String.to_existing_atom(sub_type))

  def expire_limit(token_type, sub_type) when is_atom(sub_type) do
    exp_config = getcfg(:auth_expire_limits, %{})

    case exp_config[token_type][sub_type] do
      nil ->
        IO.inspect([token_type, sub_type], label: "Lookup keys")
        raise "Invalid Configuration"

      pass ->
        pass
    end
  end

  def getcfg(name, default), do: Application.get_env(:rivet_ident, name, default)
  def putcfg(value, name), do: Application.put_env(:rivet_ident, name, value)

  defp to_map(list) do
    if Keyword.keyword?(list) do
      Map.new(list, fn {k, v} ->
        {as_atom(k), to_map(v)}
      end)
    else
      list
    end
  end
end
