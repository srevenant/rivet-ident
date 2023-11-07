defmodule Rivet.Ident.User.Notify.UserVerification do
  alias Rivet.Ident
  use Rivet.Email.Template

  require Logger

  @reset_code_expire_mins 1_440
  def sendto(%Ident.Email{address: eaddr, user: user} = email) do
    with {:ok, code} <-
           Ident.UserCode.Lib.generate_code(
             email.user_id,
             :email_verify,
             @reset_code_expire_mins,
             %{
               email_id: email.id
             }
           ) do
      Logger.info("added email", user_id: user.id, eaddr: eaddr)
      Rivet.Email.mailer().sendto(email, __MODULE__, code: code.code)
    end
  end
end
