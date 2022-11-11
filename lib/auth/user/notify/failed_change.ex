defmodule Rivet.Data.Auth.User.Notify.FailedChange do
  alias Rivet.Data.Auth
  use Rivet.Email.Template

  ##############################################################################
  def send(%Auth.UserEmail{} = email, action),
    do: @sender.send(email, __MODULE__, action: action)

  @behaviour Rivet.Ecto.Collection
  @impl Rivet.Email.Template
  def generate(%Auth.UserEmail{}, attr) do
    {:ok, "#{attr.org} Account Change Failed",
     """
     <p/>
     We recently received a request to #{attr.action}, but it was unsuccessful.
     <p/>
     If you did not request this change, you can ignore this email and nothing will change.
     <p/>
     #{attr.email_sig}
     """}
  end
end
