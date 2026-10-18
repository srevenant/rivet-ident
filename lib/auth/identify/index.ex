defmodule Rivet.Auth.Identify do
  use Rivet.Ident
  alias Rivet.Auth

  @spec identify(String.t(), map()) :: {:ok | :error, Auth.Domain.t()} | {:exists, %Email{}}
  def identify(hostname, %{email: address}) do
    Ident.User.Signup.signup(
      %Auth.Domain{hostname, input: %{email: %{address, verified: false}, settings: %{}}},
      :identity
    )
  end
end
