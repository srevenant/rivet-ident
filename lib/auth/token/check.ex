defmodule Rivet.Auth.Token.Check do
  @moduledoc """
  Validate tokens are meeting our requirements
  """
  alias Rivet.Auth
  use Rivet.Ident
  import Transmogrify.As

  def jwt(%Auth.Domain{} = auth) do
    # order matters
    # - audience parses the token type
    # - expiration is based on the token type
    # - after which it is worth looking up the subject
    # - signature is different based on audience/type and the subject, so do it last
    auth
    |> enrich_sub_aud()
    |> valid_audience()
    |> valid_expiration()
    |> valid_subject()
  end

  ###########################################################################
  def enrich_sub_aud(%Auth.Domain{token: %{claims: %{sub: sub, aud: aud}}} = auth) do
    with {:ok, sub} <- expand_claim_value(:sub, sub),
         {:ok, aud} <- expand_claim_value(:aud, aud) do
      %Auth.Domain{auth | token: Map.merge(auth.token, Map.merge(aud, sub))}
    else
      error -> auth_error(auth, error)
    end
  end

  def enrich_sub_aud(auth), do: auth_error(auth, "Unable to check JWT, missing sub/aud")

  defp expand_claim_value(key, val) do
    with [type, value] <- String.split(val, ":", parts: 2) do
      tkey = as_atom!("#{key}_type")
      atype = as_atom!(type)
      {:ok, %{key => value, tkey => atype}}
    else
      _err ->
        {:error, "Cannot parse token.#{key}=#{val}"}
    end
  end

  ###########################################################################
  def valid_audience(%Auth.Domain{token: %{aud}} = auth) do
    case expand_claim_value(:tok, aud) do
      {:ok, %{tok: t_hostname, tok_type: t_type}} ->
        if auth.hostname == t_hostname do
          %Auth.Domain{auth | type: t_type, hostname: t_hostname}
        else
          auth_error(auth, "Token audience does not match: '#{t_hostname}' != '#{auth.hostname}'")
        end

      reason ->
        auth_error(auth, reason)
    end
  end

  def valid_audience({:error, _} = pass), do: pass

  ###########################################################################
  def valid_expiration(%Auth.Domain{token: %{claims: %{for: scope} = claims}, type: type} = auth) do
    now = System.os_time(:second)
    expires = claims.exp

    if is_number(expires) and expires > now do
      max_exp = Rivet.Auth.Settings.expire_limit(type, Map.get(scope, :type))
      delta = expires - now

      if delta > max_exp do
        auth_error(auth, "Token expiration out of bounds")
      else
        %Auth.Domain{auth | expires: expires}
      end
    else
      auth_error(auth, "Token Expired")
    end
  end

  def valid_expiration({:error, _} = pass), do: pass

  ###########################################################################
  def valid_subject(%Auth.Domain{type: :acc, token: %{sub_type: :cas1, sub: sub}} = auth) do
    case Factor.Lib.get_user(sub) do
      # type: :valtok is correct. The factor is the parent validation token
      # which created this access token, we are just looking through it to the user
      {:ok, %Factor{type: :valtok} = factor} ->
        {:ok, %Auth.Domain{auth | factor: factor, user: factor.user}}

      {:ok, %Factor{}} ->
        auth_error(auth, "Provided factor is not a validation token")

      error ->
        auth_error(auth, error)
    end
  end

  def valid_subject(
        %Auth.Domain{token: %{aud_type: :caa1, sub_type: :cas1, sub: sub}, type: :val} = auth
      ) do
    case Factor.Lib.get_user(sub) do
      {:ok, %Factor{type: :valtok} = factor} ->
        if is_nil(factor.value) do
          auth_error(auth, "Factor for token is not a validation factor")
        else
          {:ok, %Auth.Domain{auth | factor: factor}}
        end

      {:ok, _} ->
        auth_error(auth, "Factor for token is not a validation factor(2)")

      error ->
        auth_error(auth, error)
    end
  end

  def valid_subject(%Auth.Domain{token: %{claims: %{sub: sub}}} = auth) do
    auth_error(auth, "Cannot parse token.sub=#{sub}")
  end

  def valid_subject(%Auth.Domain{} = auth),
    do: auth_error(auth, "Unable to process token subject")

  def valid_subject({:error, _} = pass), do: pass

  ###########################################################################
  # DRY
  defp auth_error(auth, {:error, reason}), do: {:error, %Auth.Domain{auth | log: reason}}
  defp auth_error(auth, reason), do: {:error, %Auth.Domain{auth | log: reason}}
end
