defmodule Rivet.Ident.Context do
  defmacro __using__(_) do
    quote location: :keep do
      @notify_password_changed Application.get_env(
                                 :rivet_ident,
                                 :notify_password_changed,
                                 Rivet.Ident.User.Notify.PasswodChanged
                               )
      @notify_password_reset Application.get_env(
                               :rivet_ident,
                               :notify_password_reset,
                               Rivet.Ident.User.Notify.Passwordeset
                             )
      @notify_user_failed_change Application.get_env(
                                   :rivet_ident,
                                   :notify_user_failed_change,
                                   Rivet.Ident.User.Notify.FaildChange
                                 )
      @notify_user_verification Application.get_env(
                                  :rivet_ident,
                                  :notify_user_verification,
                                  Rivet.Ident.User.Notify.Verifcation
                                )
    end
  end
end
