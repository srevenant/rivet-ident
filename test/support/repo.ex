defmodule Cato.Data.Repo do
  @moduledoc false
  use Ecto.Repo, otp_app: :cato_data_auth, adapter: Ecto.Adapters.Postgres
end
