defmodule Rivet.Ident.Example.Mailer.Template do
  use Rivet.Email.Template

  @impl Rivet.Email.Template
  def send(targets, assigns), do: Rivet.Email.mailer().send(targets, __MODULE__, assigns)

  @impl Rivet.Email.Template
  def generate(recip, attrs) do
    {:ok, "test subject",
     "<p>Welcome #{recip.user.name}<p>This is a test from #{attrs.email_from}"}
  end
end
