defmodule Rivet.Ident do
  # runtime so we avoid circular dependencies
  def mailer_template(key), do: Application.get_env(:rivet, :mailer_templates)[key]

  def critical_report(msg, opts \\ []),
    do: mailer_template(:critical_fail).report(msg, opts)

  def critical_report_if_error(result, msg, opts \\ []),
    do: mailer_template(:critical_fail).report_if_error(result, msg, opts)

  # defp enum_list(caller, key) do
  #   # to/from map to assure its in kw format
  #   Application.compile_env!(caller, :rivet_ident, key) |> Map.new() |> Map.to_list()
  # end

  @enums Application.compile_env(:rivet_ident, :defenums, [])

  for {module, values} <- @enums do
    Rivet.Ecto.DefEnum.create_enum!(module, values, __ENV__)
  end

  defmacro __using__(_opts) do
    org_model = Application.compile_env!(__CALLER__, :rivet, :org_model)
    repo = Application.compile_env!(__CALLER__, :rivet, :repo)

    # access_domains = enum_list(__CALLER__, :access_domains)
    # user_code_types = enum_list(__CALLER__, :user_code_types)

    quote location: :keep do
      # note: the reason for no alias Rivet.Auth is `Auth` can be a common
      # module name so to avoid external conflicts, it is excluded
      alias Rivet.Ident
      alias Rivet.Ident.{User, Handle, Email, Factor, Access}

      ## TODO: revise; this isn't going to work as the `use` here is still
      ## internal to this app. we need something that points to the external
      ## app configs
      alias unquote(org_model), as: Org
      @repo unquote(repo)

      # @access_domains unquote(access_domains)
      # @user_code_types unquote(user_code_types)

      import Rivet.Guards
      import Rivet.Ident

      import Rivet.Ecto.DefEnum
    end
  end
end
