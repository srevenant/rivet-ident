import Config

config :logger, level: :info

config :rivet,
  repo: Rivet.Data.Repo,
  ecto_repos: [Rivet.Data.Repo],
  table_prefix: ""

config :rivet, Rivet.Email,
  enabled: false,
  sender: Rivet.Email.Example

config :rivet, Rivet.Data.Ident,
  # ecto_repos: [Rivet.Data.Repo],
  reset_code_expire_mins: 1440,
  notify_templates: [
    failed_change: Rivet.Data.Ident.User.Notify.FailedChange,
    verification: Rivet.Data.Ident.User.Notify.Verification,
    password_reset: Rivet.Data.Ident.User.Notify.PasswordReset,
    password_changed: Rivet.Data.Ident.User.Notify.PasswordChanged
  ],
  table_prefix: "ident_",
  table_names: [
    accesses: "accesses",
    actions: "actions",
    emails: "emails",
    factors: "factors",
    handles: "handles",
    phones: "phones",
    roles: "roles",
    role_maps: "role_maps",
    users: "users",
    user_codes: "user_codes",
    user_datas: "user_datas"
  ]

config :rivet, Rivet.Data.Repo,
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
