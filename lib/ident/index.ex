defmodule Rivet.Ident do

  # runtime so we avoid circular dependencies
  def mailer_template(key), do: Application.get_env(:rivet, :mailer_templates)[key]

  def critical_report(msg, opts),
    do: mailer_template(:critical_fail).report(msg, opts)

  def critical_report_if_error(result, msg, opts),
    do: mailer_template(:critical_fail).report_if_error(result, msg, opts)

  defmacro __using__(_) do
    org_model = Application.compile_env!(__CALLER__, :rivet, :org_model)
    repo = Application.compile_env!(__CALLER__, :rivet, :repo)

    quote location: :keep do
      alias Rivet.Ident.{User, UserCode, Email}
      alias unquote(org_model), as: Org
      alias unquote(repo), as: Repo

      import Rivet.Guards
      import Rivet.Ident
    end
  end
end
