defmodule Rivet.Auth.Refresh do
  @moduledoc """
  Tooling for the second phase of auth: Refresh

  TODO: Extract from Phoenix/WebSvc better, abstract so conn isn't needed
        This will require a module that is imported into WebSvc -BJG
  """
  alias Rivet.Auth

  @doc """
  1. extract the validaton token from the refresh token
  2. decode & verify the validation token is ours & good
  3. using the sub:uuid from the validation token, verify the signature on the ref token
  4. update connection data (or abort)

  iex> assure(%Auth.Domain{}, nil)
  {:error, %Auth.Domain{log: "Invalid refresh request"}}
  """
  def assure(%Auth.Domain{} = auth, %{"client_assertion" => refresh_token})
      when is_binary(refresh_token) do
    auth = %Auth.Domain{auth | token: %{ref: refresh_token}}

    # do this manually first
    Auth.Token.extract(refresh_token, :claims)
    |> extract_validation_token(auth)
    |> check_refresh_token
  end

  def assure(_arg, _params) do
    {:error, %Auth.Domain{log: "Invalid refresh request"}}
  end

  ##############################################################################
  @doc ~S"""
  iex> {:error, %Auth.Domain{log: "Invalid authorization"}} = extract_validation_token({:ok, %{sub: "cas2:asdf"}}, %Auth.Domain{})
  iex> {:error, %Auth.Domain{log: "Unable to match validation token subject: \"wut\""}} = extract_validation_token({:ok, "wut"}, %Auth.Domain{})
  iex> {:error, %Auth.Domain{log: "narf!"}} = extract_validation_token({:error, "narf!"}, %Auth.Domain{})
  """
  def extract_validation_token({:ok, %{sub: "cas2:" <> validation_token}}, auth) do
    # now check the signature
    case Auth.Token.Verify.jwt(validation_token, :val) do
      {:error, reason} ->
        {:error, %Auth.Domain{auth | log: reason}}

      {:ok, result} ->
        valauth = %Auth.Domain{
          auth
          | status: :authed,
            token: %{ref: validation_token, claims: result}
        }

        # this checks the validation token embedded within the refresh token
        case Auth.Token.Check.jwt(valauth) do
          {:ok, %Auth.Domain{} = valauth} ->
            {:ok, auth, valauth}

          {:error, %Auth.Domain{} = auth} ->
            {:error, auth}
        end
    end
  end

  def extract_validation_token({:error, reason}, auth) when is_binary(reason) do
    {:error, %Auth.Domain{auth | log: reason}}
  end

  # turn it into an error if we didn't match above
  def extract_validation_token({:ok, args}, auth),
    do:
      {:error, %Auth.Domain{auth | log: "Unable to match validation token subject: #{inspect(args)}"}}

  ##############################################################################
  @doc """
  iex> {:error, "narf!"} = check_refresh_token({:error, "narf!"})
  """
  def check_refresh_token(
        {:ok, %Auth.Domain{token: %{ref: token}} = refauth,
         %Auth.Domain{factor: %Rivet.Ident.Factor{value: secret}} = valauth}
      )
      when not is_nil(secret) do
    case Auth.Token.Verify.jwt(token, [secret]) do
      {:ok, _} ->
        {:ok, %Auth.Domain{refauth | status: :authed}, valauth}

      {:error, msg} ->
        {:error, %Auth.Domain{refauth | log: "Unable to verify refresh token signature: #{msg}"}}
    end
  end

  def check_refresh_token(pass = {:error, _reason}), do: pass
end
