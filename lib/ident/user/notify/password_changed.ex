defmodule Rivet.Ident.User.Notify.PasswordChanged do
  alias Rivet.Ident
  use Rivet.Email.Template
  require Logger

  ##############################################################################
  # preload to send to all and not filter verified
  def send(%Ident.User{} = user) do
    with {:ok, user} <- Ident.User.preload(user, [:emails]) do
      Rivet.Email.mailer().send(user.emails, __MODULE__)
    end
  end

  @impl Rivet.Email.Template
  def generate(%Ident.Email{} = email, attr) do
    with {:error, error} <- load(email, attr) do
      Logger.warn(error)

      {:ok, "#{attr.org} email notification - password changed",
       """
       <p/>
       The account at #{attr.org} associated with this email had its password changed.
       <p/>
       #{attr.email_sig}
       """}
    end
  end
end
