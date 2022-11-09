import Config

config :unify, repo: Cato.Data.Repo
config :cato_data_auth, ecto_repos: [Cato.Data.Repo]

config :cato_data_auth, Cato.Data.Repo,
  pool_size: 20,
  username: "postgres",
  password: "",
  database: "cato_#{config_env()}",
  hostname: "localhost",
  log: false,
  pool: Ecto.Adapters.SQL.Sandbox

# Print only warnings and errors during test
config :logger, level: :warn

config :ex_unit, capture_log: true
