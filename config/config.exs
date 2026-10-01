import Config

config :logger, level: :info
config :ex_unit, capture_log: true

config :rivet,
  app: :rivet_ident,
  repo: Rivet.Auth.Repo,
  org_model: Rivet.Org,
  test: true,
  mailer_templates: %{
    critical_fail: Rivet.Mailer.CriticalFail,
    system_error: Rivet.Mailer.SystemError,
    password_changed: Rivet.Ident.Test.NotifyTemplate,
    password_reset: Rivet.Ident.Test.NotifyTemplate,
    user_failed_change: Rivet.Ident.Test.NotifyTemplate,
    user_verification: Rivet.Ident.Test.NotifyTemplate
  }

config :rivet_ident,
  ecto_repos: [Rivet.Auth.Repo],
  federated: %{google: true},
  initial_password_expiration_days: 7,
  jwt_acc_secrets: [""],
  jwt_val_secrets: [""],
  jwt_api_secrets: [""],
  auth_expire_limits: %{
    val: %{
      acc: 60 * 60 * 24 * 30,
      api: 60 * 60 * 24 * 365
    },
    ref: 15 * 60,
    acc: 60 * 60 * 24,
    api: 15 * 60,
    password: 365 * 86400
  }

config :rivet_ident, Rivet.Auth.Repo,
  migration_repo: Rivet.Auth.Repo,
  pool_size: 20,
  username: "postgres",
  password: "",
  database: "rivet_ident_#{config_env()}",
  hostname: "localhost",
  log: false,
  pool: Ecto.Adapters.SQL.Sandbox

import_config "#{config_env()}.exs"
