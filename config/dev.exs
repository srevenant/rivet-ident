import Config

config :rivet_data_auth, Rivet.Data.Repo,
  pool_size: 10,
  username: "postgres",
  password: "",
  database: "rivet_#{config_env()}",
  hostname: "db",
  log: false
