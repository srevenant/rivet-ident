defmodule Rivet.Auth.Identify do
  @moduledoc """
  """
  alias Rivet.{Ident, Auth}

  ###########################################################################
  @doc """
  """
  @spec identify(String.t(), map()) :: {:ok | :error, Auth.Domain.t()} | {:exists, %Ident.Email{}}
  def identify(hostname, %{email: address}) do
    case Ident.Email.all!(address: address) do
      [%Ident.Email{} = email] ->
        {:exists, email}

      _other ->
        # create new user profile with identity info only
        Ident.User.Signup.signup(
          %Auth.Domain{hostname, input: %{email: %{address, verified: false}, settings: %{}}},
          :identify
        )
    end
  end

  def identify(_, _), do: :error
end
