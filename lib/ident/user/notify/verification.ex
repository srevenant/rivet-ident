defmodule Rivet.Data.Ident.User.Notify.Verification do
  use Rivet.Data.Ident.Config
  alias Rivet.Data.Ident
  use Rivet.Email.Template
  require Logger

  def send(%Ident.Email{address: eaddr, user: user} = email) do
    with {:ok, code} <-
           Ident.UserCode.Db.generate_code(
             email.user_id,
             :email_verify,
             @reset_code_expire_mins,
             %{
               email_id: email.id
             }
           ) do
      Logger.info("added email", user_id: user.id, eaddr: eaddr)
      @sender.send(email, __MODULE__, code: code)
    end
  end

  @behaviour Rivet.Ecto.Collection
  @impl Rivet.Email.Template
  def generate(%Ident.Email{}, attr) do
    {:ok, "#{attr.org} email verification",
     """
     <p/>
     This email was added to an account at #{attr.org}.  However, it is not yet verified.  Please verify this email address by clicking the Verify link:
     <p/>
     <a href="#{attr.link_back}/ev?code=#{attr.code}">Verify</a>
     <p/>
     If you are unable to view or click the link in this message, copy the following URL and paste it in your browser:
     <p/><code>#{attr.link_back}/ev?code=#{attr.code}</code>
     <p/>
     This verification code will expire in 1 day.
     <p/>
     #{attr.email_sig}
     """}
  end
end
