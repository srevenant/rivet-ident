import Config

config :logger, :console,
  format: {Rivet.Utils.UniformLogFormat, :format},
  metadata: :all

config :logger, level: :info
config :ex_unit, capture_log: true

config :rivet,
  app: :rivet_ident,
  repo: Rivet.Ident.Test.Repo,
  user_model: Rivet.Ident.User,
  user_code_model: Rivet.Ident.User.Code,
  email_model: Rivet.Ident.Email,
  org_model: Rivet.Org,
  handle_model: Rivet.Ident.Handle,
  test: true,
  mailer_templates: %{
    critical_fail: Rivet.Ident.Test.NullTemplate,
    system_error: Rivet.Ident.Test.NullTemplate,
    password_changed: Rivet.Ident.Test.NullTemplate,
    password_reset: Rivet.Ident.Test.NullTemplate,
    user_failed_change: Rivet.Ident.Test.NullTemplate,
    user_verification: Rivet.Ident.Test.NullTemplate
  }

config :rivet_ident,
  ecto_repos: [Rivet.Ident.Test.Repo],
  federated: %{
    google: true,
    google_client_id: "test-google-client"
  },
  password_history: 2,
  password_min_length: 9,
  initial_password_expiration_days: 7,
  jwt_acc_secrets: ["AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="],
  jwt_val_secrets: ["AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="],
  jwt_api_secrets: ["AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="],
  auth_expire_limits: %{
    val: %{
      acc: 60 * 60 * 24 * 30,
      api: 60 * 60 * 24 * 365
    },
    ref: 15 * 60,
    acc: 60 * 60 * 24,
    api: 15 * 60,
    password: 2 * 86400
  },
  #################
  defenums: [
    {Rivet.Ident.Access.Domains, global: 0},
    {Rivet.Ident.Email.Status, pending: 0, verified: 1, bouncing: 2, complaint: 3, rejected: 4},
    {Rivet.Ident.User.Code.Types, password_reset: 0, email_verify: 1, delete_request: 3},
    {Rivet.Ident.User.Data.Types, address: 2, profile: 4, toggles: 5, save: 6}
  ],
  extend_user: []

config :rivet_ident, Rivet.Ident.Test.Repo,
  migration_repo: Rivet.Ident.Test.Repo,
  pool_size: 20,
  username: "postgres",
  password: "",
  database: "rivet_ident_#{config_env()}",
  hostname: "localhost",
  log: false,
  pool: Ecto.Adapters.SQL.Sandbox

import_config "#{config_env()}.exs"
