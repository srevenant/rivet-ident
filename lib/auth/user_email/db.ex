defmodule Rivet.Data.Auth.UserEmail.Db do
  alias Rivet.Data.Auth
  use Rivet.Ecto.Collection.Context

  ##############################################################################
  @doc """
  Helper function which accepts either user_id or user, and calls the passed
  function with the user model loaded including any preloads.  Send preloads
  as [] if none are desired.
  """
  def with_email(%Auth.UserEmail{} = email, preloads, func) do
    with {:ok, email} <- Auth.UserEmail.preload(email, preloads) do
      func.(email)
    end
  end

  def with_email(email, preloads, func) when is_binary(email) do
    case Auth.UserEmail.one([address: email], preloads) do
      {:error, _} = pass ->
        pass

      {:ok, %Auth.UserEmail{} = email} ->
        func.(email)
    end
  end
end
