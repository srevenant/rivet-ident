import Config

config :logger, level: :info

config :rivet, repo: Rivet.Repo

config :rivet_email,
  enabled: false,
  sender: Rivet.Email.Example

config :rivet_data_auth,
  ecto_repos: [Rivet.Data.Repo],
  reset_code_expire_mins: 1440,
  user_notify_failed_change: Rivet.Data.Auth.User.Notify.FailedChange,
  user_notify_verification: Rivet.Data.Auth.User.Notify.Verification,
  user_notify_password_reset: Rivet.Data.Auth.User.Notify.PasswordReset,
  user_notify_password_changed: Rivet.Data.Auth.User.Notify.PasswordChanged

config :rivet_data_auth, Rivet.Data.Repo,
  pool_size: 20,
  username: "postgres",
  password: "",
  database: "rivet_#{config_env()}",
  hostname: "localhost",
  log: false,
  pool: Ecto.Adapters.SQL.Sandbox

import_config "#{config_env()}.exs"
