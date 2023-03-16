defmodule Rivet.Auth.Identify do
  @moduledoc """
  """
  alias Rivet.{Ident, Auth}

  ###########################################################################
  @doc """
  """
  @spec identify(String.t(), map()) :: {:ok | :error, Auth.Domain.t()} | {:exists, %Ident.Email{}}
  def identify(hostname, %{email: eaddr}) do
    case Ident.Email.all!(address: eaddr) do
      [%Ident.Email{} = email] ->
        {:exists, email}

      _other ->
        # create new user profile with identity info only
        Ident.User.Lib.Signup.only_identity(%Auth.Domain{
          hostname: hostname,
          input: %{email: %{address: eaddr, verified: false}, settings: %{}}
        })
    end
  end

  def identify(_, _), do: :error
end
