defmodule Rivet.Data.Ident.Email.Db do
  alias Rivet.Data.Ident
  use Rivet.Ecto.Collection.Context

  ##############################################################################
  @doc """
  Helper function which accepts either user_id or user, and calls the passed
  function with the user model loaded including any preloads.  Send preloads
  as [] if none are desired.
  """
  def with_email(%Ident.Email{} = email, preloads, func) do
    with {:ok, email} <- Ident.Email.preload(email, preloads) do
      func.(email)
    end
  end

  def with_email(email, preloads, func) when is_binary(email) do
    case Ident.Email.one([address: email], preloads) do
      {:error, _} = pass ->
        pass

      {:ok, %Ident.Email{} = email} ->
        func.(email)
    end
  end
end
