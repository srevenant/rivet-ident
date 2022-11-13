defmodule Rivet.Data.Ident do
  @moduledoc """
  Rivets Models for Identity management things.
  """
  import Rivet.Utils.Types, only: [as_atom: 1]

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      @ident_notify Application.compile_env!(:rivet, Rivet.Data.Ident)[:notify_templates]
      @ident_notify_failed_change @ident_notify[:failed_change]
      @ident_notify_verification @ident_notify[:verification]
      @ident_notify_password_reset @ident_notify[:password_reset]
      @ident_notify_password_changed @ident_notify[:password_changed]

      @rivet_table_prefix Application.compile_env!(:rivet, :table_prefix) || ""
      @ident_table_prefix Application.compile_env!(:rivet, Rivet.Data.Ident)[:table_prefix] ||
                            "ident_"
      @ident_table_names Application.compile_env!(:rivet, Rivet.Data.Ident)[:table_names]
                         |> Map.new(fn {k, v} ->
                           {k, as_atom("#{@rivet_table_prefix}#{@ident_table_prefix}#{v}")}
                         end)
      @ident_table_accesses @ident_table_names.accesses
      @ident_table_actions @ident_table_names.actions
      @ident_table_emails @ident_table_names.emails
      @ident_table_factors @ident_table_names.factors
      @ident_table_handles @ident_table_names.handles
      @ident_table_phones @ident_table_names.phones
      @ident_table_roles @ident_table_names.roles
      @ident_table_role_maps @ident_table_names.role_maps
      @ident_table_users @ident_table_names.users
      @ident_table_user_codes @ident_table_names.user_codes
      @ident_table_user_datas @ident_table_names.user_datas

      @reset_code_expire_mins Application.compile_env!(:rivet, Rivet.Data.Ident)[
                                :reset_code_expire_mins
                              ]
    end
  end
end
