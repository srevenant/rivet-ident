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

  @impl Rivet.Email.Template
  def generate(%Ident.Email{address: _} = email, attrs) when is_map(attrs) do
    with {:error, error} <- load(email, attr) do
      Logger.warn(error)
      link = "#{attrs.link_front}/pwreset/#{attrs.code}"

      {:ok, "#{attrs.org} Password Reset",
       """
       <p/>
       We recently received a request to a password on an email associated with your account (#{attrs.reqaddr}).
       If you initiated this request, you can reset your password with this one-time-use code by clicking
       the Reset Password link:
       <p/>
       <a href="#{link}">Reset Password</a>
       <p/>
       If you are unable to view or click the link in this message, copy the following URL and paste it in your browser:
       <p/><code>#{link}</code>
       <p/>
       This reset code will expire in 1 hour.
       <p/>
       If you did not request this change, you can ignore this email and your password will not be changed.
       <p/>
       #{attrs.email_sig}
       """}
    end
  end
end
