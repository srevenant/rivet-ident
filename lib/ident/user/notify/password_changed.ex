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
end
