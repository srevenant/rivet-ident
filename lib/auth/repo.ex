defmodule Rivet.Auth.Repo do
  @moduledoc false
  use Ecto.Repo, otp_app: :rivet_auth, adapter: Ecto.Adapters.Postgres
end
