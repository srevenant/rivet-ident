defmodule Rivet.Ident.User.Notify.FailedChange do
  alias Rivet.Ident
  use Rivet.Email.Template

  ##############################################################################
  def send(%Ident.Email{} = email, action),
    do: Rivet.Email.mailer().send(email, __MODULE__, action: action)

  @behaviour Rivet.Ecto.Collection
  @impl Rivet.Email.Template
  def generate(%Ident.Email{}, attr) when is_map(attr) do
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
