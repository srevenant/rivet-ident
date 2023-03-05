defmodule Rivet.Auth.Refresh do
  @moduledoc """
  Tooling for the second phase of auth: Refresh

  TODO: Extract from Phoenix/WebSvc better, abstract so conn isn't needed
        This will require a module that is imported into WebSvc -BJG
  """
  alias Rivet.Auth.Domain
  alias Rivet.Auth.Token

  @doc """
  1. extract the validaton token from the refresh token
  2. decode & verify the validation token is ours & good
  3. using the sub:uuid from the validation token, verify the signature on the ref token
  4. update connection data (or abort)

  iex> assure(%Domain{}, nil)
  {:error, %Domain{log: "Invalid refresh request"}}
  """
  def assure(%Domain{} = auth, %{"client_assertion" => refresh_token})
      when is_binary(refresh_token) do
    auth = %Domain{auth | token: %{ref: refresh_token}}

    # do this manually first
    Token.extract(refresh_token, :claims)
    |> extract_validation_token(auth)
    |> check_refresh_token
  end

  def assure(_arg, _params) do
    {:error, %Domain{log: "Invalid refresh request"}}
  end

  ##############################################################################
  @doc ~S"""
  iex> {:error, %Domain{log: "Invalid authorization"}} = extract_validation_token({:ok, %{sub: "cas2:asdf"}}, %Domain{})
  iex> {:error, %Domain{log: "Unable to match validation token subject: \"wut\""}} = extract_validation_token({:ok, "wut"}, %Domain{})
  iex> {:error, %Domain{log: "narf!"}} = extract_validation_token({:error, "narf!"}, %Domain{})
  """
  def extract_validation_token({:ok, %{sub: "cas2:" <> validation_token}}, auth) do
    # now check the signature
    case Token.Verify.jwt(validation_token, :val) do
      {:error, reason} ->
        {:error, %Domain{auth | log: reason}}

      {:ok, result} ->
        valauth = %Domain{
          auth
          | status: :authed,
            token: %{ref: validation_token, claims: result}
        }

        # this checks the validation token embedded within the refresh token
        case Token.Check.jwt(valauth) do
          {:ok, %Domain{} = valauth} ->
            {:ok, auth, valauth}

          {:error, %Domain{} = auth} ->
            {:error, auth}
        end
    end
  end

  def extract_validation_token({:error, reason}, auth) when is_binary(reason) do
    {:error, %Domain{auth | log: reason}}
  end

  # turn it into an error if we didn't match above
  def extract_validation_token({:ok, args}, auth),
    do:
      {:error, %Domain{auth | log: "Unable to match validation token subject: #{inspect(args)}"}}

  ##############################################################################
  @doc """
  iex> {:error, "narf!"} = check_refresh_token({:error, "narf!"})
  """
  def check_refresh_token(
        {:ok, %Domain{token: %{ref: token}} = refauth,
         %Domain{factor: %Rivet.Data.Ident.Factor{value: secret}} = valauth}
      )
      when not is_nil(secret) do
    case Token.Verify.jwt(token, [secret]) do
      {:ok, _} ->
        {:ok, %Domain{refauth | status: :authed}, valauth}

      {:error, msg} ->
        {:error, %Domain{refauth | log: "Unable to verify refresh token signature: #{msg}"}}
    end
  end

  def check_refresh_token(pass = {:error, _reason}), do: pass
end
