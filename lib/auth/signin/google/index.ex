defmodule Rivet.Auth.Signin.Google do
  @moduledoc """
  Google login scheme
  """
  alias Rivet.Auth
  alias Rivet.Auth.Domain
  alias Rivet.Data.Ident

  # TODO:
  # - pull imageUrl (tiff?) and converts it / uploads it into user's profile

  ##############################################################################
  # note: this is different from `Domain.result()` typedef, in it can have any
  # value with :ok, where the second part of Domain.result() is always an Domain
  @spec check(String.t(), map()) :: Domain.result()
  def check(hostname, %{"data" => %{"auth" => token}}) when is_binary(hostname) do
    verify_google_signature(token)
    |> find_or_create_user(hostname)
    |> Rivet.Auth.Signin.post_signin()
  end

  def check(_, _) do
    {:error, %Domain{}, {"auth signup failed, invalid arguments from client", "Signup Failed"}}
  end

  ##############################################################################
  @spec verify_google_signature(String.t()) ::
          {:ok, %{payload: map(), header: map(), token: String.t()}}
          | {:error, Domain.t()}
  defp verify_google_signature(token) do
    case Auth.Token.extract(token, :header) do
      {:ok, header} ->
        # from the unverified header we pull the google key, and index that against
        # the keys we have from google, to get the pubkey (jwk) that will check the
        # signature of this jwt
        google_keys = Auth.Signin.Google.KeyManager.get_keys()
        jwk = Map.get(google_keys, header["kid"])
        auth = %Domain{token: token}

        case JOSE.JWT.verify_strict(jwk, ["RS256"], token) do
          {true, %JOSE.JWT{fields: fields}, %JOSE.JWS{} = jws} ->
            {:ok, %{payload: fields, header: Map.from_struct(jws), token: token}}

          {false, %JOSE.JWT{fields: %{"email" => email}}, %JOSE.JWS{}} ->
            {:error, %Domain{auth | log: "Unable to verify google token for #{email}"}}

          {:error, _rest} ->
            {:error, %Domain{auth | log: "Unable to verify google JWT"}}
        end

      {:error, reason} ->
        {:error, %Domain{log: reason}}
    end
  end

  ##############################################################################
  defp find_or_create_user({:ok, %{payload: %{"email_verified" => true} = payload}}, hostname) do
    payload
    |> find_user(hostname)
    |> update_user_avatar(payload["picture"])
  end

  defp find_or_create_user(pass, _), do: pass

  ###############################################################################
  defp update_user_avatar(
         {:ok, %Domain{status: :authed, user: %Ident.User{} = _}} = pass,
         _picurl
       ) do
    IO.puts("Need to get avatar")
    # 1. see if user has avatar
    # 2. if not, in async process pull URL and submit as avatar
    pass
  end

  defp update_user_avatar(pass, _), do: pass

  ###############################################################################
  defp find_user(%{"sub" => ident} = params, hostname) do
    case Ident.UserIdent.Lib.get("google", ident) do
      {:ok, user_ident} -> Ident.User.one(id: user_ident.user_id) |> check_user_allowed(hostname)
      _ -> find_user_by_email(params, hostname)
    end
  end

  defp find_user(_, _),
    do: {:error, "Unrecognized payload values, cannot continue; missing 'sub'"}

  ###############################################################################
  defp find_user_by_email(%{"email" => email, "sub" => ident} = params, hostname) do
    case Ident.Email.one([address: email], [:user]) do
      {:ok, %Ident.Email{user: %Ident.User{} = u}} ->
        {:ok, u}
        |> check_user_allowed(hostname)
        |> add_ident(ident)

      _ ->
        create_user(params, hostname)
    end
  end

  defp google_allowed?(user) do
    case get_in(user.settings, ["authAllowed", "google"]) do
      nil -> true
      value -> value
    end
  end

  defp check_user_allowed({:ok, %Ident.User{} = user}, hostname) do
    if google_allowed?(user) and Ident.User.enabled?(user) do
      {:ok, %Domain{hostname: hostname, status: :authed, user: user}}
    else
      {:error,
       %Domain{
         log: "Federated signin when user already exists",
         error:
           "The user has already signed in, but has not authorized google logins. You can try to reset your password."
       }}
    end
  end

  defp check_user_allowed(x, _) do
    IO.inspect(x)
    {:error, %Domain{log: "User identified but unable to load"}}
  end

  ##############################################################################
  defp create_user(params, hostname) do
    fedid = payload_to_fedid(params)

    Ident.User.Lib.signup(%Domain{
      hostname: hostname,
      status: :authed,
      input: %{
        fedid: fedid,
        name: params["name"],
        handle: fedid.handle,
        # todo: we should retain the 'verified' on this email
        email: fedid.email,
        # pass this through
        email_verified: true,
        settings: %{authAllowed: Map.put(fedid.settings, fedid.provider.type, true)}
      }
    })
    |> add_ident(params["sub"])
  end

  # ##############################################################################
  defp add_ident({:ok, %Domain{user: %Ident.User{} = u}} = pass, ident) do
    with {:ok, _} <- Ident.UserIdent.Lib.put(u, "google", ident) do
      pass
    end
  end

  defp add_ident(pass, _), do: pass

  ##############################################################################
  #  defp link_factor({:ok, %Ident.User{} = user}) do
  #
  #   {
  #   "iss": "https://accounts.google.com",
  #   "nbf": 1111111115,
  #   "aud": "311111111124-ecb8lih2719bbpe1tv1itiq003p7pa4h.apps.googleusercontent.com",
  #   "sub": "111111111111111111354",
  #   "hd": "cdomain",
  #   "email": "user@domain",
  #   "email_verified": true,
  #   "azp": "310dfasdfasdf-ecb7lih2717bbpe1td3itiq003e7pn4h.apps.googleusercontent.com",
  #   "name": "Joe Friday",
  #   "picture": "https://lh3.googleusercontent.com/a/AEwFTp5SjTOtm4RJ176koDsSEmkXv6o_7hTf1ueeZBOk=s96-c",
  #   "given_name": "Joe",
  #   "family_name": "Friday",
  #   "iat": 1111111975,
  #   "exp": 1111111575,
  #   "jti": "casfdasdfasdfasdfasdf"
  # }
  defp payload_to_fedid(payload) do
    %Ident.Factor.FedId{
      name: payload["name"],
      handle: Ident.Handle.Lib.gen_good_handle(payload["email"]),
      email: %Ident.Factor.FedId.Email{
        address: payload["email"],
        verified: true
      },
      phone: nil,
      settings: %{
        locale: payload["locale"]
      },
      provider: %Ident.Factor.FedId.Provider{
        type: :google,
        sub: payload["sub"],
        jti: payload["jti"],
        iss: payload["iss"],
        iat: payload["iat"],
        exp: payload["exp"],
        azp: payload["azp"],
        aud: payload["aud"],
        token: payload["token"]
      }
    }
  end
end
