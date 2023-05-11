defmodule Rivet.Ident.User.Notify.Verification do
  alias Rivet.Ident
  use Rivet.Email.Template

  require Logger

  @reset_code_expire_mins 1_440
  def send(%Ident.Email{address: eaddr, user: user} = email) do
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
      Rivet.Email.mailer().send(email, __MODULE__, code: code.code)
    end
  end

  @impl Rivet.Email.Template
  def generate(%Ident.Email{} = email, attr) do
    with {:error, error} <- load(email, attr) do
      Logger.warn(error)

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
end
