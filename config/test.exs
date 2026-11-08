import Config

config :rivet_ident,
  defenums: [
    # this is the only change, but the whole set needs to be updated
    {Rivet.Ident.Access.Domains, global: 0, project: 1},
    {Rivet.Ident.Email.Status, pending: 0, verified: 1, bouncing: 2, complaint: 3, rejected: 4},
    {Rivet.Ident.User.Code.Types, password_reset: 0, email_verify: 1, delete_request: 3},
    {Rivet.Ident.User.Data.Types, address: 2, profile: 4, toggles: 5, save: 6, social: 20}
  ]
