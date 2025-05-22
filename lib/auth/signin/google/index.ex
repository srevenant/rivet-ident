defmodule Rivet.Auth.Signin.Google do
  @moduledoc """
  Google login scheme
  """
  alias Rivet.Ident
  alias Rivet.Auth

  # TODO:
  # - pull imageUrl (tiff?) and converts it / uploads it into user's profile

  ##############################################################################
  # note: this is different from `Auth.Domain.result()` typedef, in it can have any
  # value with :ok, where the second part of Auth.Domain.result() is always an Auth.Domain
  @spec check(String.t(), map()) :: Auth.Domain.result()
  def check(hostname, args, type \\ :authed)

  def check(hostname, %{"data" => %{"auth" => token}}, type) when is_binary(hostname) do
    verify_google_signature(token)
    |> find_or_create_user(hostname, type)
    |> Auth.Signin.post_signin()
  end

  def check(_, _, _),
    do:
      {:error,
       %Auth.Domain{
         error: "Signup Failed",
         log: "auth signup failed, invalid arguments from client"
       }}

  ##############################################################################
  @spec verify_google_signature(String.t()) ::
          {:ok, %{payload: map(), header: map(), token: String.t()}}
          | {:error, Auth.Domain.t()}
  defp verify_google_signature(token) do
    case Auth.Token.extract(token, :header) do
      {:ok, header} ->
        # from the unverified header we pull the google key, and index that against
        # the keys we have from google, to get the pubkey (jwk) that will check the
        # signature of this jwt
        google_keys = Auth.Signin.Google.KeyManager.get_keys()
        jwk = Map.get(google_keys, header["kid"])
        auth = %Auth.Domain{token: token}

        case JOSE.JWT.verify_strict(jwk, ["RS256"], token) do
          {true, %JOSE.JWT{fields: fields}, %JOSE.JWS{} = jws} ->
            {:ok, %{payload: fields, header: Map.from_struct(jws), token: token}}

          {false, %JOSE.JWT{fields: %{"email" => email}}, %JOSE.JWS{}} ->
            {:error, %Auth.Domain{auth | log: "Unable to verify google token for #{email}"}}

          _ ->
            {:error, %Auth.Domain{auth | log: "Unable to verify google JWT"}}
        end

      {:error, reason} ->
        {:error, %Auth.Domain{log: reason}}
    end
  end

  ##############################################################################
  defp find_or_create_user(
         {:ok, %{payload: %{"email_verified" => true} = payload}},
         hostname,
         type
       ) do
    payload
    |> find_user(hostname, type)
    |> update_user_avatar(payload["picture"])
  end

  defp find_or_create_user(pass, _, _), do: pass

  ###############################################################################
  # defp update_user_avatar(
  # {:ok, %Auth.Domain{status: :authed, user: %Ident.User{} = _}} = pass,
  # _picurl
  # ) do
  # IO.puts("Need to get avatar")
  ## 1. see if user has avatar
  ## 2. if not, in async process pull URL and submit as avatar
  # pass
  # end

  defp update_user_avatar(pass, _), do: pass

  ###############################################################################
  defp find_user(%{"sub" => ident} = params, hostname, type) do
    case Ident.UserIdent.Lib.get("google", ident) do
      {:ok, user_ident} -> Ident.User.one(id: user_ident.user_id) |> check_user_allowed(hostname)
      _ -> find_user_by_email(params, hostname, type)
    end
  end

  defp find_user(_, _, _),
    do: {:error, "Unrecognized payload values, cannot continue; missing 'sub'"}

  ###############################################################################
  defp find_user_by_email(%{"email" => email, "sub" => ident} = params, hostname, type) do
    case Ident.Email.one([address: email], [:user]) do
      {:ok, %Ident.Email{user: %Ident.User{} = u}} ->
        {:ok, u}
        |> check_user_allowed(hostname)
        |> add_ident(ident)

      _ ->
        create_user(params, hostname, type)
    end
  end

  defp google_allowed?(user) do
    case get_in(user.settings, ["authAllowed", "google"]) do
      nil ->
        # add google in if it wasn't set at all
        settings =
          case user.settings do
            %{"authAllowed" => _} -> put_in(user.settings, ["authAllowed", "google"], true)
            _ -> Map.put(user.settings, "authAllowed", %{"google" => true})
          end

        with {:error, err} <- Ident.User.update(user, %{settings: settings}) do
          IO.inspect(err, label: "Unexpected error updating user settings on signin")
        end

        true

      value ->
        value
    end
  end

  defp check_user_allowed({:ok, %Ident.User{} = user}, hostname) do
    if google_allowed?(user) and Ident.User.enabled?(user) do
      {:ok, %Auth.Domain{hostname: hostname, status: :authed, user: user}}
    else
      {:error,
       %Auth.Domain{
         log: "Federated signin when user already exists",
         error:
           "The user has already signed in, but has not authorized google logins. You can try to reset your password."
       }}
    end
  end

  defp check_user_allowed(_, _),
    do: {:error, %Auth.Domain{log: "User identified but unable to load"}}

  ##############################################################################
  defp create_user(params, hostname, type) do
    fedid = payload_to_fedid(params)

    Rivet.Auth.Signin.create_user(fedid.handle, fedid.email.address, hostname, type, %{
      fedid: fedid,
      name: params["name"],
      settings: %{"authAllowed" => %{"google" => true}}
    })
    |> add_ident(params["sub"])
  end

  # ##############################################################################
  defp add_ident({:ok, %Auth.Domain{user: %Ident.User{} = u}} = pass, ident) do
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
    # could update locale if we have it here in settings
    %Ident.Factor.FedId{
      name: payload["name"],
      handle: Ident.Handle.Lib.gen_good_handle(payload["email"]),
      email: %Ident.Factor.FedId.Email{
        address: payload["email"],
        verified: true
      },
      phone: nil,
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
