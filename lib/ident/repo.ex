defmodule Rivet.Auth.Repo do
  @moduledoc false
  use Ecto.Repo, otp_app: :rivet_ident, adapter: Ecto.Adapters.Postgres
end
