defmodule Rivet.Email.Example do
  @moduledoc """
  This is an example of how to deploy Rivet Email, and is included so other
  projects may include it in their tests.
  """
  alias Rivet.Email.Example
  alias Rivet.Ident

  use Rivet.Email,
    otp_app: :rivet_auth,
    user_model: Ident.User,
    email_model: Ident.Email,
    mailer: Example.Mailer
end
