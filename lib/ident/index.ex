defmodule Rivet.Ident do
  def cfg(key), do: Application.get_env(:rivet_ident, key)
end
