import Config

config :cato_data_auth, Cato.Data.Repo,
  pool_size: 10,
  username: "postgres",
  password: "",
  database: "cato_#{config_env()}",
  hostname: "db",
  log: false
