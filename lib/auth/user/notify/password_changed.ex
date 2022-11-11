defmodule Rivet.Data.Auth.User.Notify.PasswordChanged do
  alias Rivet.Data.Auth
  use Rivet.Email.Template

  ##############################################################################
  # preload to send to all and not filter verified
  def send(%Auth.User{} = user) do
    with {:ok, user} <- Auth.User.preload(user, :emails) do
      @sender.send(user.emails, __MODULE__)
    end
  end

  @impl Rivet.Email.Template
  def generate(%Auth.UserEmail{}, attr) do
    {:ok, "#{attr.org} email notification - password changed",
     """
     <p/>
     The account at #{attr.org} associated with this email had its password changed.
     <p/>
     #{attr.email_sig}
     """}
  end
end
