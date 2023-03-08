defmodule Rivet.Ident.Email.Lib do
  alias Rivet.Ident
  use Rivet.Ecto.Collection.Context, model: Ident.Email

  ##############################################################################
  @doc """
  Helper function which accepts either user_id or user, and calls the passed
  function with the user model loaded including any preloads.  Send preloads
  as [] if none are desired.
  """
  def with_email(%Ident.Email{} = email, preloads, func) do
    with {:ok, email} <- Ident.Email.preload(email, preloads) do
      func.(email)
    end
  end

  def with_email(email, preloads, func) when is_binary(email) do
    case Ident.Email.one([address: email], preloads) do
      {:error, _} = pass ->
        pass

      {:ok, %Ident.Email{} = email} ->
        func.(email)
    end
  end

  @expire_minutes 60
  def send_reset_code(%Ident.Email{user: %Ident.User{} = user} = email) do
    Ident.UserCode.Lib.clear_all_codes(user.id, :password_reset)

    case Ident.UserCode.Lib.generate_code(user.id, :password_reset, @expire_minutes) do
      {:ok, code} ->
        Ident.User.Notify.PasswordReset.send(user, email, code)
        :ok

      error ->
        IO.inspect(error, label: "Cannot generate UserCode?")
        :error
    end
  end
end
