alias Rivet.Ident.Access.Migrations, as: M

[
  # ONLY for codex prod
  [base: true, version: 12, module: M.V12ChangeDomainAgain],
  [base: true, version: 11, module: M.V11NoId],
  [base: true, version: 10, module: M.V10ChangeDomain],
  [base: true, version: 0, module: M.Base]
]
