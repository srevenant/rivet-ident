defmodule Rivet.Auth.Token.Check do
  @moduledoc """
  Validate tokens are meeting our requirements
  """
  alias Rivet.Auth
  alias Rivet.Ident
  import Rivet.Utils.Types, only: [as_atom: 1]

  @doc ~S"""
  Checks payload information to verify proper authorization matches

  iex> {:ok, _token, claims} = Rivet.Auth.Token.Access.jwt("narf", "example.com", 5)
  ...> {:error, %Auth.Domain{} = a} = jwt(%Auth.Domain{hostname: "example.com", token: %{claims: claims}})
  ...> a.log
  "Cannot find identity factor=narf"

  """
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
  @doc """
  iex> alias Rivet.Ident.Auth.Domain
  iex> {:error, auth} = enrich_sub_aud(%Auth.Domain{token: %{claims: %{sub: "asdf", aud: "asdf"}}})
  iex> auth.log
  "Cannot parse token.sub=asdf"
  """
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
      tkey = as_atom("#{key}_type")
      atype = as_atom(type)
      {:ok, %{key => value, tkey => atype}}
    else
      _err ->
        {:error, "Cannot parse token.#{key}=#{val}"}
    end
  end

  ###########################################################################
  @doc """
  iex> alias Rivet.Ident.Auth.Domain
  iex> {:error, auth} = valid_audience(%Auth.Domain{token: %{aud: "asdf"}})
  iex> auth.log
  "Cannot parse token.tok=asdf"
  iex> {:error, auth} = valid_audience(%Auth.Domain{token: %{aud: "key:a.domain"}, hostname: "b.domain"})
  iex> auth.log
  "Token audience does not match: a.domain != b.domain"
  iex> valid_audience({:error, "narf"})
  {:error, "narf"}
  """
  def valid_audience(%Auth.Domain{token: %{aud: audience}} = auth) do
    case expand_claim_value(:tok, audience) do
      {:ok, %{tok: t_hostname, tok_type: t_type}} ->
        if auth.hostname == t_hostname do
          %Auth.Domain{auth | type: t_type, hostname: t_hostname}
        else
          auth_error(auth, "Token audience does not match: #{t_hostname} != #{auth.hostname}")
        end

      reason ->
        auth_error(auth, reason)
    end
  end

  def valid_audience({:error, _} = pass), do: pass

  ###########################################################################
  @doc """
  iex> alias Rivet.Ident.Auth.Domain
  iex> now = System.os_time(:second)
  iex> {:error, auth} = valid_expiration(%Auth.Domain{token: %{claims: %{for: %{}, exp: 0}}, type: :acc})
  iex> auth.log
  "Token Expired"
  iex> {:error, auth} = valid_expiration(%Auth.Domain{token: %{claims: %{for: %{}, exp: now+300000}}, type: :acc})
  iex> auth.log
  "Token expiration out of bounds"
  iex> valid_expiration({:error, "narf"})
  {:error, "narf"}
  """
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
  @doc """
  iex> alias Rivet.Ident.Auth.Domain
  iex> {:error, auth} = valid_subject(%Auth.Domain{})
  iex> auth.log
  "Unable to process token subject"
  iex> {:error, auth} = valid_subject(%Auth.Domain{token: %{claims: %{sub: "red"}}, type: :acc})
  iex> auth.log
  "Cannot parse token.sub=red"
  iex> {:error, auth} = valid_subject(%Auth.Domain{type: :acc, token: %{sub_type: :cas1, sub: "subject"}})
  iex> auth.log
  "Cannot find identity factor=subject"
  iex> {:error, auth} = valid_subject(%Auth.Domain{token: %{aud_type: :caa1, sub_type: :cas1, sub: "subject"}, type: :val})
  iex> auth.log
  "Cannot find identity factor=subject"
  iex> valid_subject({:error, "narf"})
  {:error, "narf"}
  """
  def valid_subject(%Auth.Domain{type: :acc, token: %{sub_type: :cas1, sub: sub}} = auth) do
    case Ident.Factor.Lib.get_user(sub) do
      # type: :valtok is correct. The factor is the parent validation token
      # which created this access token, we are just looking through it to the user
      {:ok, %Ident.Factor{type: :valtok} = factor} ->
        {:ok, %Auth.Domain{auth | factor: factor, user: factor.user}}

      {:ok, %Ident.Factor{}} ->
        auth_error(auth, "Provided factor is not a validation token")

      error ->
        auth_error(auth, error)
    end
  end

  def valid_subject(
        %Auth.Domain{token: %{aud_type: :caa1, sub_type: :cas1, sub: sub}, type: :val} = auth
      ) do
    case Ident.Factor.Lib.get_user(sub) do
      {:ok, %Ident.Factor{type: :valtok} = factor} ->
        if is_nil(factor.value) do
          auth_error(auth, "Factor for token is not a validation factor")
        else
          {:ok, %Auth.Domain{auth | factor: factor}}
        end

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
