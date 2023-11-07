defmodule Rivet.Ident.Context do
  defmacro __using__(_) do
    quote location: :keep do
      @notify_password_changed notifier(
                                 :notify_password_changed,
                                 Rivet.Ident.User.Notify.PasswodChanged
                               )
      @notify_password_reset notifier(
                               :notify_password_reset,
                               Rivet.Ident.User.Notify.Passwordeset
                             )
      @notify_user_failed_change notifier(
                                   :notify_user_failed_change,
                                   Rivet.Ident.User.Notify.FaildChange
                                 )
      @notify_user_verification notifier(
                                  :notify_user_verification,
                                  Rivet.Ident.User.Notify.Verifcation
                                )

      def notifier(key, default), do: Application.get_env(:rivet_ident, key, default)
    end
  end
end
