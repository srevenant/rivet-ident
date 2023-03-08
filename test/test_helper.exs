ExUnit.start(capture_log: true)

Supervisor.start_link([{Rivet.Auth.Repo, []}],
  strategy: :one_for_one,
  name: Rivet.Ident.Supervisor
)

ExUnit.configure(exclude: [pending: true], formatters: [JUnitFormatter, ExUnit.CLIFormatter])
# Ecto.Adapters.SQL.Sandbox.mode(Rivet.Repo, :manual)
Faker.start()
