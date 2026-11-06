alias Rivet.Ident.Access.Migrations, as: M

[
  [base: true, version: 12, module: M.V12ChangeDomainAgain],
  # no flip back to ID? why no ID?
  [base: true, version: 11, module: M.V11AddId],
  [base: true, version: 10, module: M.V10ChangeDomain],
  [base: true, version: 0, module: M.Base]
]
