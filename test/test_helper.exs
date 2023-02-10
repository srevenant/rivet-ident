ExUnit.start(capture_log: true)

Supervisor.start_link([{Rivet.Data.Ident.Repo, []}],
  strategy: :one_for_one,
  name: Rivet.Data.Ident.Supervisor
)

ExUnit.configure(exclude: [pending: true], formatters: [JUnitFormatter, ExUnit.CLIFormatter])
# Ecto.Adapters.SQL.Sandbox.mode(Rivet.Data.Repo, :manual)
Faker.start()
