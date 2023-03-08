import Config

config :rivet_auth,
  jwt_acc_secrets: [
    "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
  ],
  jwt_val_secrets: [
    "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
  ],
  jwt_api_secrets: [
    "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
  ]

config :rivet_email,
  enabled: false,
  sender: Rivet.Email.Example
