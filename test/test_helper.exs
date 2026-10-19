ExUnit.start(capture_log: true)

Supervisor.start_link([{Rivet.Ident.Test.Repo, []}],
  strategy: :one_for_one,
  name: Rivet.Ident.Supervisor
)

ExUnit.configure(exclude: [pending: true], formatters: [JUnitFormatter, ExUnit.CLIFormatter])

Faker.start()

Rivet.Auth.Settings.start()

children = [
  Rivet.Auth.Cache,
  Rivet.Ident.Role.Cache,
  Rivet.Ident.Factor.Cache,
  Rivet.Ident.User.Cache
]

children =
  case Application.get_env(:rivet_ident, :federated) do
    %{google: true} ->
      [
        {Rivet.Auth.Signin.Google.KeyManager, %{interval: 400_000_000}}
        | children
      ]

    _ ->
      children
  end

Supervisor.start_link(children, strategy: :one_for_one)
