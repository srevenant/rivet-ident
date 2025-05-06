defmodule Rivet.Ident.Example.Mailer.Configurator do
  use Rivet.Email.Configurator, otp_app: :rivet_ident
end

defmodule Rivet.Ident.Example.Mailer do
  @moduledoc """
  This is an example of how to deploy Rivet Email, and is included so other
  projects may include it in their tests.
  """
  alias Rivet.Ident.Example.Mailer

  use Rivet.Email,
    otp_app: :rivet_ident,
    backend: Mailer.Backend,
    configurator: Mailer.Configurator,
    # using something besides Ident.User/Email
    user_model: Rivet.Ident.User,
    email_model: Rivet.Ident.Email
end
