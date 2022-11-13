defmodule Rivet.Data.Repo do
  @moduledoc false
  use Ecto.Repo, otp_app: :rivet_data_ident, adapter: Ecto.Adapters.Postgres
end
