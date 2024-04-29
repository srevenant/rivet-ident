defmodule Rivet.Ident.Test.NotifyTemplate do
  use Rivet.Email.Template

  def queue(_), do: :ok
end
