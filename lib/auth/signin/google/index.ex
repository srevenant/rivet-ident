defmodule Rivet.Auth.Signin.Google do
  @moduledoc """

  Google login scheme

  TODO? pull imageUrl (tiff?) and converts it / uploads it into user's profile

  """
  use Rivet.Ident
  alias Rivet.Auth
  require Logger

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

  def check(_, _, _), do: signin_error("Invalid arguments")

  ##############################################################################
  @spec verify_google_signature(String.t()) ::
          {:ok, %{payload: map(), header: map(), token: String.t()}}
          | {:error, Auth.Domain.t()}

  if Mix.env() == :test do
    defp verify_google_signature("test:" <> encoded = token) do
      with {:ok, json} <- Base.url_decode64(encoded, padding: false),
           {:ok, claims} <- Jason.decode(json),
           :ok <- valid_claims(claims) do
        {:ok, %{token: token, payload: claims, header: %{}}}
      else
        {:error, what} -> signin_error("test_wrapped_error: " <> what)
      end
    end
  end

  ###
  ### because of the nature of this checking against google directly, this is
  ### not covered in normal tests, alas.
  ###
  # coveralls-ignore-start
  defp verify_google_signature(token) do
    case Auth.Token.extract(token, :header) do
      {:ok, header} ->
        # from the unverified header we pull the google key, and index that against
        # the keys we have from google, to get the pubkey (jwk) that will check the
        # signature of this jwt
        google_keys = Auth.Signin.Google.KeyManager.get_certs()
        jwk = Map.get(google_keys, header["kid"])

        case JOSE.JWT.verify_strict(jwk, ["RS256"], token) do
          {true, %JOSE.JWT{fields: payload}, %JOSE.JWS{} = jws} ->
            case valid_claims(payload) do
              :ok -> {:ok, %{token, payload, header: Map.from_struct(jws)}}
              {:error, what} -> signin_error(what)
            end

          {false, %JOSE.JWT{fields: %{"email" => email}}, %JOSE.JWS{}} ->
            signin_error("Unable to verify google token for #{email}")

          _ ->
            signin_error("Unable to verify google JWT")
        end

      {:error, reason} ->
        signin_error(reason)
    end
  end

  # coveralls-ignore-stop

  @good_iss ["accounts.google.com", "https://accounts.google.com"]
  defp valid_claims(token) do
    case Rivet.Auth.Settings.getcfg(:federated, %{}) do
      %{google_client_id: google_aud, google: true} when not_empty_str(google_aud) ->
        with %{"exp" => exp, "iss" => iss, "aud" => aud} when is_integer(exp) <- token,
             true <- exp > System.system_time(:second) and iss in @good_iss and aud == google_aud do
          :ok
        else
          _ ->
            {:error, "Invalid Google ID token"}
        end

      # coveralls-ignore-next-line
      _ ->
        {:error, "Google federated signin not enabled or federated.google_client_id is unset"}
    end
  end

  ##############################################################################
  # only allow signin with google users who have verified their email
  defp find_create_by_ident(%{"email_verified" => true, "sub" => ident} = params, h, type) do
    case User.ExtId.Lib.get("google", ident) do
      {:ok, user_ident} -> User.one(id: user_ident.user_id) |> check_user_allowed(h)
      {:error, :not_found} -> find_create_by_email(params, h, type)
    end
  end

  defp find_create_by_ident(_, _, _),
    do: signin_error("Cannot sign in: federated identity is incomplete.")

  ####
  defp find_create_by_email(%{"email" => email, "sub" => ident} = params, hostname, type) do
    case Ident.Email.one([address: email], [:user]) do
      {:ok, %Ident.Email{user: %User{} = u, verified: true}} ->
        check_user_allowed({:ok, u}, hostname) |> add_ident(ident)

      {:ok, %Ident.Email{verified: false}} ->
        signin_error("User identified but email is unverified. Please verify that first.")

      {:error, :not_found} ->
        create_user(params, hostname, type)
    end
  end

  ##############################################################################
  defp google_allowed_update(user) do
    case get_in(user.settings, ["authAllowed", "google"]) do
      nil ->
        # add google in if it wasn't set at all
        settings =
          case user.settings do
            %{"authAllowed" => _} ->
              put_in(user.settings, ["authAllowed", "google"], true)

            _ ->
              # This is not getting covered
              Map.put(user.settings, "authAllowed", %{"google" => true})
          end

        User.update(user, %{settings})
        |> Rivet.Ident.critical_report_if_error(
          "Unexpected error updating user settings on signin"
        )

      true ->
        {:ok, user}

      false ->
        {:error, "You have disabled google logins. Perhaps try to reset your password?"}
    end
  end

  def check_user_allowed({:ok, %User{} = user}, hostname) do
    with {:ok, user} <- Rivet.Ident.User.Lib.check_user_status(user) do
      case google_allowed_update(user) do
        {:ok, user} -> {:ok, %Auth.Domain{hostname, user, status: :authed}}
        {:error, msg} -> signin_error("Federated signin disabled for user", msg)
      end
    end
  end

  def check_user_allowed(_, _),
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
  def add_ident({:ok, %Auth.Domain{user: %User{} = u}} = pass, ident) do
    with {:ok, _} <- User.ExtId.Lib.put(u, "google", ident), do: pass
  end

  def add_ident(pass, _), do: pass

  ##############################################################################
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

  def signin_error(log, error \\ "Unable to sign in."),
    do: {:error, %Auth.Domain{error, log: "Google signin failed: #{log}", status: :unknown}}
end
