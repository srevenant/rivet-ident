defmodule Rivet.Ident.Test.NullTemplate do
  # use Rivet.Email.Template

  def queue(_), do: :ok
  def report(a, _), do: {:error, a}
  def report_if_error(_, b, _), do: {:error, b}
end
