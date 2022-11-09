ExUnit.start(capture_log: true)
{:ok, _} = Application.ensure_all_started(:ex_machina)

Supervisor.start_link([{Cato.Data.Repo, []}],
  strategy: :one_for_one,
  name: Cato.Data.Adi.Supervisor
)

ExUnit.configure(exclude: [pending: true], formatters: [JUnitFormatter, ExUnit.CLIFormatter])
# Ecto.Adapters.SQL.Sandbox.mode(Cato.Data.Repo, :manual)
Faker.start()
