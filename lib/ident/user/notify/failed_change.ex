defmodule Rivet.Ident.User.Notify.FailedChange do
  alias Rivet.Ident
  use Rivet.Email.Template
  require Logger

  ##############################################################################
  def send(%Ident.Email{} = email, action),
    do: Rivet.Email.mailer().send(email, __MODULE__, action: action)
end
