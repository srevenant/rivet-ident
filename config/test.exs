import Config

config :rivet, repo: Rivet.Data.Repo

config :rivet_email,
  enabled: false,
  sender: Rivet.Email.Example

config :rivet_data_auth, ecto_repos: [Rivet.Data.Repo]

config :rivet_data_auth, Rivet.Data.Repo,
  pool_size: 20,
  username: "postgres",
  password: "",
  database: "rivet_#{config_env()}",
  hostname: "localhost",
  log: false,
  pool: Ecto.Adapters.SQL.Sandbox

# Print only warnings and errors during test
config :logger, level: :warn

config :ex_unit, capture_log: true
