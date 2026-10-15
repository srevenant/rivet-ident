defmodule Rivet.Ident.User.Signup do
  use Rivet.Ident
  alias Rivet.Auth
  require Logger

  ################################################################################
  @doc """
  SignUp pipeline
  """
  def signup(auth, type \\ :authed)

  def signup(%Auth.Domain{hostname: h} = auth, type) when is_binary(h) do
    {:ok, auth}
    |> signup_check_handle
    |> signup_create_user(type)
    # |> signup_add_password
    # TODO: be intelligent
    |> signup_add_factor
    |> signup_associate_handle
    |> signup_associate_email
    |> mainline

    # TODO: this should actually shift to a welcome new user dialog, which can ask for other account attributes
  end

  # WAS: signup(tenant, input)
  def signup(input, _) do
    {:error,
     %Auth.Domain{
       log: "No match for signup with args:\n#{inspect(input)}",
       error: "Sign up Failed"
     }}
  end

  # variant with less restrictions
  def only_identity(%Auth.Domain{} = auth) do
    {:ok, auth}
    |> signup_create_user(:identity)
    |> signup_associate_email
    |> mainline

    # TODO: this should actually shift to a welcome new user dialog, which can ask for other account attributes
  end

  # result is any as we ignore it
  @spec signup_abort_create(Auth.Domain.t()) ::
          {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  defp signup_abort_create(auth) do
    if not is_nil(auth.user) do
      User.delete(auth.user)
    end
  end

  defp signup_check_handle(pass = {:ok, auth = %Auth.Domain{input: %{handle: handle}}}) do
    case Ident.Handle.Lib.available(handle) do
      {:ok, _available_msg} ->
        pass

      {:error, private, public} ->
        {:error, auth, {private, public}}
    end
  end

  defp signup_create_user(
         {:ok, auth = %Auth.Domain{input: input}},
         type
       ) do
    name = Map.get(input, :name, "")
    settings = Map.get(input, :settings, %{})

    case User.create(%{
           name: name,
           settings: settings,
           type: type
         }) do
      {:ok, user} ->
        {:ok, %Auth.Domain{auth | status: type, user: user, created: true}}

      {:error, err} ->
        signup_abort_create(auth)
        {:error, auth, {"Failed to create user=#{inspect(err)}", "Unable to signup at this time"}}
    end
  end

  defp signup_add_factor({:error, _auth, _reason} = pass), do: pass

  defp signup_add_factor(
         {:ok,
          auth = %Auth.Domain{
            user: %User{} = user,
            input: %{secret: secret}
          }}
       ) do
    case Ident.Factor.Lib.set_password(user, secret) do
      {:ok, %Ident.Factor{}} ->
        {:ok, auth}

      {:error, %Ecto.Changeset{} = changeset} ->
        signup_abort_create(auth)
        {:error, auth, {"", Rivet.Ecto.Errors.convert_error_changeset(changeset)}}

      {:error, reason} ->
        signup_abort_create(auth)
        {:error, auth, {"", reason}}
    end
  end

  defp signup_add_factor(
         {:ok,
          auth = %Auth.Domain{
            user: %User{} = user,
            input: %{fedid: %Ident.Factor.FedId{} = fedid}
          }}
       ) do
    case Ident.Factor.Lib.set_factor(user, fedid) do
      {:ok, %Ident.Factor{} = factor} ->
        {:ok, %Auth.Domain{auth | factor: factor}}

      {:error, %Ecto.Changeset{} = changeset} ->
        signup_abort_create(auth)
        {:error, auth, {"", Rivet.Ecto.Errors.convert_error_changeset(changeset)}}
    end
  end

  defp signup_associate_handle({:error, _auth, _reason} = pass), do: pass

  defp signup_associate_handle(
         {:ok,
          auth = %Auth.Domain{
            user: %User{} = user,
            input: %{handle: handle}
          }}
       ) do
    case Ident.Handle.create(%{handle: handle, user_id: user.id}) do
      {:ok, handle} ->
        {:ok, %Auth.Domain{auth | handle: handle}}

      {:error, %Ecto.Changeset{} = changeset} ->
        signup_abort_create(auth)

        {:error, auth, {"", Rivet.Ecto.Errors.convert_error_changeset(changeset)}}
    end
  end

  defp signup_associate_email({:error, _auth, _reason} = pass), do: pass

  defp signup_associate_email(
         {:ok,
          auth = %Auth.Domain{
            user: %User{} = user,
            input: %{email: %{address: eaddr, verified: status}}
          }}
       )
       when is_binary(eaddr) do
    case User.Lib.add_email(user, eaddr, status) do
      {:ok, email} ->
        {:ok, %Auth.Domain{auth | email: email}}

      {:error, msg} ->
        signup_abort_create(auth)
        {:error, auth, {"", msg}}
    end
  end

  # after success, create a new struct so we don't carry around unecessary or
  # insecure baggage
  defp mainline({:ok, auth = %Auth.Domain{site, hostname, user, handle, created, status}}),
    do: {:ok, %Auth.Domain{site, hostname, user, handle, created, status}}

  defp mainline({:error, _auth, {log, error}}), do: {:error, %Auth.Domain{log, error}}
end
