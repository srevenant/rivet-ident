defmodule Rivet.Data.Ident.Repo do
  use Rivet.Data.Ident.Config
  @moduledoc false
  if @test_environ do
    use Ecto.Repo, otp_app: :rivet, adapter: Ecto.Adapters.Postgres
  end
end
