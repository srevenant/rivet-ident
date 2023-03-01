import Config

config :logger, level: :info
config :ex_unit, capture_log: true

config :rivet,
  repo: Rivet.Auth.Repo,
  table_prefix: "",
  test: true

config :rivet_auth,
  federated: %{
    google: true
  },
  initial_password_expiration_days: 7,
  jwt_acc_secrets: [""],
  jwt_val_secrets: [""],
  jwt_api_secrets: [""],
  cxs_apps: %{
    supervisor: %{
      secrets: [],
      index: "0"
    }
  },
  auth_expire_limits: %{
    val: %{
      acc: 60 * 60 * 24 * 30,
      api: 60 * 60 * 24 * 365
    },
    ref: 15 * 60,
    acc: 60 * 60 * 24,
    api: 15 * 60,
    cxs: 15 * 60 * 24,
    password: 365 * 86400
  }

config :rivet_auth,
  ecto_repos: [Rivet.Auth.Repo]

# this is where you define common things used in templates
config :rivet_auth, :email,
  link_front: "http://localhost:3000",
  link_back: "http://localhost:4000",
  org: "Example Org",
  email_from: "noreply@example.com",
  email_sig: "Example Org"

config :rivet_auth, Rivet.Auth.Repo,
  migration_repo: Rivet.Auth.Repo,
  pool_size: 20,
  username: "postgres",
  password: "",
  database: "rivet_data_ident_#{config_env()}",
  hostname: "localhost",
  log: false,
  pool: Ecto.Adapters.SQL.Sandbox

config :rivet, Rivet.Data.Ident, table_prefix: "ident_"
# first_user_admin: false,
# reset_code_expire_mins: 1440,

import_config "#{config_env()}.exs"
