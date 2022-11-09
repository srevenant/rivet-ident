# Dialyzer PITA in combination w/PasswordGenerator, easier to just isolate this
# @dialyzer {:nowarn_function, [shuffle: 2]}
defmodule(Cato.Data.Auth.User.PasswordGenerator,
  do: use(RandomPassword, alpha: 8, decimal: 2, symbol: 2)
)
