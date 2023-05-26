defmodule Rivet.Ident.User.Notify.PasswordReset do
  alias Rivet.Ident
  use Rivet.Email.Template
  require Logger

  ##############################################################################
  # preload to send to all and not filter verified
  def send(%Ident.User{} = user, %Ident.Email{} = email, %Ident.UserCode{} = code) do
    with {:ok, user} <- Ident.User.preload(user, [:emails]) do
      Rivet.Email.mailer().send(user.emails, __MODULE__, reqaddr: email.address, code: code.code)
    end
  end
end
