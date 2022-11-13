defmodule Rivet.Data.Ident.User.Notify.FailedChange do
  alias Rivet.Data.Ident
  use Rivet.Email.Template

  ##############################################################################
  def send(%Ident.Email{} = email, action),
    do: @sender.send(email, __MODULE__, action: action)

  @behaviour Rivet.Ecto.Collection
  @impl Rivet.Email.Template
  def generate(%Ident.Email{}, attr) do
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
