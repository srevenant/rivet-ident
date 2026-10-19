defmodule Rivet.Ident.User.Signup do
  use Rivet.Ecto.Collection.Context, model: User
  import Rivet.Ecto.Errors, only: [convert_error_changeset: 1]
  use Rivet.Ident
  alias Rivet.Auth
  alias Factor.FedId

  @spec signup(Auth.Domain.t(), type :: :authed | :identity, keyword() | map()) ::
          {:ok, Auth.Domain.t()} | {:error, Auth.Domain.t()}

  def signup(auth, type, opts \\ %{})

  def signup(%Auth.Domain{input} = auth, :authed, opts) when is_map(input) do
    @repo.transact(fn _ ->
      with :ok <- good_password(auth),
           {:ok, %Auth.Domain{} = auth} <- new_user(auth, :authed, opts),
           do: add_factor(auth)
    end)
    |> tap(&dispatch_email(&1, opts[:no_send] || false))
    |> sanitize_errors()
  end

  def signup(%Auth.Domain{input} = auth, :identity, opts) when is_map(input) do
    @repo.transact(fn -> new_user(auth, :identity, opts) end)
    |> tap(&dispatch_email(&1, opts[:no_send] || false))
    |> sanitize_errors()
  end

  # DRYing out some things
  defp new_user(%Auth.Domain{} = auth, type, opts) do
    with {:ok, %Auth.Domain{} = auth} <- create_user(auth, type),
         {:ok, %Auth.Domain{} = auth} <- associate_email(auth, opts),
         do: add_handle(auth)
  end

  # bringing the dispatch outside the transaction; note: email queuing is async
  defp dispatch_email({:ok, %Auth.Domain{user}}, false), do: User.Lib.send_verify_email(user)
  defp dispatch_email(_, _), do: :ok

  # def signup_from_email(address, opts \\ []) do
  #   preload = Keyword.get(opts, :preload, [:user])
  #
  #   with {:error, _} <- Email.one([address: address], preload),
  #        do: signup_create_with_email(address, opts)
  # end

  ##############################################################################
  # federated ID doesn't include %{secret} at all, this will work fine. See
  # Google/Local.signin modules for more.
  def good_password(%Auth.Domain{input: %{secret}} = auth) do
    with {:error, error} <- Ident.Factor.Lib.strong_password(secret),
         do: {:error, %{auth | error}}
  end

  # federated ID has no secret
  def good_password(_), do: :ok

  ##############################################################################
  defp create_user(%Auth.Domain{input} = auth, type) do
    name = get_default_name(auth)
    settings = Map.get(input, :settings, %{})

    case User.create(%{name, settings, type, last_seen: DateTime.utc_now()}) do
      {:ok, user} ->
        {:ok, %Auth.Domain{auth | user, status: type, created: true}}

      {:error, err} ->
        # coveralls-ignore-start
        log = "Failed to create user=#{inspect(err)}"
        error = "Unable to signup at this time"
        # coveralls-ignore-stop
        {:error, %{auth | log, error}}
    end
  end

  #####
  def get_default_name(%{input: %{name}}) when not_empty_str(name), do: name
  def get_default_name(%{input: %{handle}}) when not_empty_str(handle), do: handle

  def get_default_name(%{input: %{email: %{address}}}) when not_empty_str(address),
    do: String.split(address, "@") |> List.first()

  def get_default_name(_), do: "no name"

  ##############################################################################
  defp add_handle(%Auth.Domain{} = auth) do
    case Handle.Lib.add_handle(auth) do
      {:ok, handle} -> {:ok, %Auth.Domain{auth | handle}}
      # this is an edge/db error not worth testing
      # coveralls-ignore-next-line
      {:error, e} -> error(auth, e)
    end
  end

  ##############################################################################
  # def get_site_(uuid) when is_uuid(uuid) do
  #   with {:error, :not_found} <- Core.Db.Site.one(id: uuid),
  #        do: Core.Db.Site.one(domain: uuid)
  # end
  #
  # def get_site_(domain), do: Core.Db.Site.one(domain: domain)
  #
  # def signup_create_with_email(site_ref, eaddr, opts \\ %{}) do
  #   case get_site_(site_ref) do
  #     {:ok, %Core.Db.Site{} = site} ->
  #       %Auth.Domain{
  #         hostname: site.domain,
  #         input: %{
  #           email: %{address: eaddr, verified: false}
  #         },
  #         site: site
  #       }
  #       |> new_user(:identity, opts)
  #       |> case do
  #         {:ok, %{email: %Db.Ident.Email{} = email}} -> {:ok, email}
  #         {:error, _, {inner, outer}} -> {:error, inner, outer}
  #       end
  #
  #     {:error, _} ->
  #       {:error, "Unable to find site matching: `#{site_ref}`"}
  #   end
  # end
  # when eaddr does not exist
  #
  # def signup_create_with_email(address, site, opts \\ %{}) do
  #   auth = %Auth.Domain{site, hostname: site.domain, input: %{email: %{address, verified: false}}}
  #   signup(auth, :identity, opts)
  # end

  # ##############################################################################
  # # result is any as we ignore it
  # ### todo: flip to transaction
  # @spec signup_abort_create(Auth.Domain.t()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  # defp signup_abort_create(auth) do
  #   if not is_nil(auth.user) do
  #     User.delete(auth.user)
  #   end
  # end

  ##############################################################################
  # set password
  defp add_factor(%Auth.Domain{user: %User{}, input: %{secret}} = auth)
       when not_empty_str(secret) do
    case Ident.Factor.Lib.set_password(auth.user, secret) do
      {:ok, %Ident.Factor{}} -> {:ok, auth}
      # this is an edge/db error not worth testing
      # coveralls-ignore-next-line
      {:error, e} -> error(auth, e)
    end
  end

  # set fedid
  defp add_factor(%Auth.Domain{user: %User{}, input: %{fedid: %FedId{} = fedid}} = auth) do
    case Ident.Factor.Lib.set_federated_factor(auth.user, fedid) do
      {:ok, %Ident.Factor{} = factor} -> {:ok, %Auth.Domain{auth | factor}}
      # this is an edge/db error not worth testing
      # coveralls-ignore-next-line
      {:error, e} -> error(auth, e)
    end
  end

  defp add_factor(%Auth.Domain{} = auth), do: error(auth, "Unable to add user factor")

  ##############################################################################
  # coveralls-ignore-next-line
  defp error(auth, %Ecto.Changeset{} = chg),
    do: {:error, %{auth | error: convert_error_changeset(chg)}}

  defp error(auth, error), do: {:error, %{auth | error}}

  ##############################################################################
  defp associate_email(%Auth.Domain{user: %User{}, input: %{email: %{address}}} = auth, opts)
       when is_binary(address) do
    verified = auth.input.email[:verified] || false
    opts = Map.new(opts) |> Map.put(:verified, verified)

    case User.Lib.add_email(auth.user, address, opts) do
      {:ok, email} -> {:ok, %Auth.Domain{auth | email}}
      # this is an edge/db error not worth testing
      # coveralls-ignore-next-line
      {:error, msg} -> error(auth, msg)
    end
  end

  defp associate_email(%Auth.Domain{} = auth, _opts), do: error(auth, "Email address required")

  ##############################################################################
  # after success, create a new struct so we don't carry around uneccessary or
  # insecure baggage
  defp sanitize_errors({:ok, %Auth.Domain{site, hostname, user, handle, created, status}}),
    do: {:ok, %Auth.Domain{site, hostname, user, handle, created, status}}

  defp sanitize_errors(pass), do: pass
end
