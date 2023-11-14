defmodule Rivet.Ident.User.Notify.UserFailedChange do
  alias Rivet.Ident
  use Rivet.Email.Template
  require Logger

  ##############################################################################
  def sendto(%Ident.Email{} = email, action),
    do: Rivet.Email.mailer().sendto(email, __MODULE__, action: action)
end
