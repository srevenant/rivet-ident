defmodule Rivet.Auth.Signin.Google do
  @moduledoc """

  Google login scheme

  TODO? pull imageUrl (tiff?) and converts it / uploads it into user's profile

  """
  use Rivet.Ident
  alias Rivet.Auth
  import Rivet.Auth.Signin

  ##############################################################################
  # note: this is different from `Auth.Domain.result()` typedef, in it can have any
  # value with :ok, where the second part of Auth.Domain.result() is always an Auth.Domain
  @spec check(String.t(), map()) :: Auth.Domain.result()
  def check(hostname, args, type \\ :authed)

  def check(hostname, %{"data" => %{"auth" => token}}, type)
      when not_empty_str(hostname) and not_empty_str(token) do
    with {:ok, %{payload}} <- verify_google_signature(token),
         {:ok, %Auth.Domain{} = auth} <- find_create_by_ident(payload, hostname, type),
         # make sure its okay without {:ok
         do: Auth.Signin.post_signin(auth)
  end

  def check(_, _, _), do: signup_error("Invalid arguments")

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
        google_keys = Auth.Signin.Google.KeyManager.get_certs()
        jwk = Map.get(google_keys, header["kid"])
        # auth = %Auth.Domain{token: token}

        case JOSE.JWT.verify_strict(jwk, ["RS256"], token) do
          {true, %JOSE.JWT{fields: fields}, %JOSE.JWS{} = jws} ->
            {:ok, %{token, payload: fields, header: Map.from_struct(jws)}}

          {false, %JOSE.JWT{fields: %{"email" => email}}, %JOSE.JWS{}} ->
            signin_error("Unable to verify google token for #{email}")

          _ ->
            signin_error("Unable to verify google JWT")
        end

      {:error, reason} ->
        signin_error(reason)
    end
  end

  # defp token_error(token,

  ##############################################################################
  # only allow signin with google users who have verified their email
  def find_create_by_ident(%{"email_verified" => true, "sub" => ident} = params, h, type) do
    case User.ExtId.Lib.get("google", ident) do
      {:ok, user_ident} -> User.one(id: user_ident.user_id) |> check_user_allowed(h)
      {:error, :not_found} -> find_create_by_email(params, h, type)
    end
  end

  def find_create_by_ident(_, _, _),
    do: {:error, "Cannot sign in: federated identity is incomplete."}

  ####
  defp find_create_by_email(%{"email" => email, "sub" => ident} = params, hostname, type) do
    case Ident.Email.one([address: email], [:user]) do
      {:ok, %Ident.Email{user: %User{} = u}} ->
        check_user_allowed({:ok, u}, hostname) |> add_ident(ident)

      {:error, :not_found} ->
        create_user(params, hostname, type)
    end
  end

  ##############################################################################
  defp google_allowed?(user) do
    case get_in(user.settings, ["authAllowed", "google"]) do
      nil ->
        # add google in if it wasn't set at all
        settings =
          case user.settings do
            %{"authAllowed" => _} -> put_in(user.settings, ["authAllowed", "google"], true)
            _ -> Map.put(user.settings, "authAllowed", %{"google" => true})
          end

        User.update(user, %{settings: settings})
        |> Rivet.Ident.critical_report_if_error(
          "Unexpected error updating user settings on signin"
        )

        true

      value ->
        value
    end
  end

  defp check_user_allowed({:ok, %User{} = user}, hostname) do
    if google_allowed?(user) and User.enabled?(user) do
      {:ok, %Auth.Domain{hostname: hostname, status: :authed, user: user}}
    else
      signin_error(
        "Federated signin when user already exists",
        "The user has already signed in, but has not authorized google logins. You can try to reset your password."
      )
    end
  end

  defp check_user_allowed(_, _),
    do: signin_error("User identified but unable to load")

  ##############################################################################
  defp create_user(params, hostname, type) do
    fedid = payload_to_fedid(params)
    email = %{address: fedid.email.address, verified: false}

    input = %{
      fedid,
      email,
      handle: fedid.handle,
      name: params["name"],
      # email_verified: false,
      settings: %{"authAllowed" => Map.put(fedid.settings, "#{fedid.provider.type}", true)}
    }

    User.Signup.signup(
      %Auth.Domain{
        hostname,
        input,
        status: :authed
      },
      type
    )
    |> add_ident(params["sub"])
  end

  ##############################################################################
  defp add_ident({:ok, %Auth.Domain{user: %User{} = u}} = pass, ident) do
    with {:ok, _} <- User.ExtId.Lib.put(u, "google", ident), do: pass
  end

  defp add_ident(pass, _), do: pass

  defp payload_to_fedid(payload) do
    # could update locale if we have it here in settings
    %Ident.Factor.FedId{
      name: payload["name"],
      handle: Ident.Handle.Lib.gen_good_handle!(payload["email"]),
      email: %Ident.Factor.FedId.Email{
        address: payload["email"],
        verified: false
      },
      phone: nil,
      settings: %{locale: payload["locale"]},
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
