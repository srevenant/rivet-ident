import Config

config :logger, level: :info
config :ex_unit, capture_log: true

config :rivet,
  repo: Rivet.Auth.Repo,
  table_prefix: "",
  app: :rivet_ident,
  test: true

config :rivet_ident,
  federated: %{
    google: true
  },
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
  },
  notify_password_changed: Rivet.Ident.Test.NotifyTemplate,
  notify_password_reset: Rivet.Ident.Test.NotifyTemplate,
  notify_user_failed_change: Rivet.Ident.Test.NotifyTemplate,
  notify_user_verification: Rivet.Ident.Test.NotifyTemplate

# to keep the compiling functional, even if it doesn't work
config :rivet_email,
  enabled: false,
  mailer: Rivet.Ident.Example.Mailer,
  site: [
    # link_front: "http://localhost:3000",
    # link_back: "http://localhost:4000",
    # org: "Example Org",
    # email_sig: "Example Org"
    email_from: "noreply@example.com"
  ]

config :rivet_email, Rivet.Ident.Example.Mailer.Backend,
  adapter: Bamboo.SMTPAdapter,
  server: "mail.example.com",
  hostname: "example.com",
  port: 25,
  tls: :if_available,
  retries: 2,
  no_mx_lookups: true,
  auth: :if_available

config :rivet_ident,
  ecto_repos: [Rivet.Auth.Repo]

# this is where you define common things used in templates
config :rivet_ident, :email,
  link_front: "http://localhost:3000",
  link_back: "http://localhost:4000",
  org: "Example Org",
  email_from: "noreply@example.com",
  email_sig: "Example Org"

config :rivet_ident, Rivet.Auth.Repo,
  migration_repo: Rivet.Auth.Repo,
  pool_size: 20,
  username: "postgres",
  password: "",
  database: "rivet_data_ident_#{config_env()}",
  hostname: "localhost",
  log: false,
  pool: Ecto.Adapters.SQL.Sandbox

config :rivet, Rivet.Ident, table_prefix: "ident_"
# first_user_admin: false,
# reset_code_expire_mins: 1440,

import_config "#{config_env()}.exs"
