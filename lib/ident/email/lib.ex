defmodule Rivet.Ident.Email.Lib do
  use Rivet.Ident
  import Ecto.Query

  @doc """
  alias Rivet.Ident.{User,Email}
  iex> has_verified?(%User{emails: [%Email{verified: true}]})
  true
  iex> %{user} = insert(:ident_email, verified: false)
  iex> has_verified?(user)
  false
  """
  def has_verified?(%User{emails: [%{verified: true}]}), do: true

  def has_verified?(%User{id}) do
    from(e in Email, where: e.user_id == ^id and e.verified)
    |> Repo.exists?()
  end

  @doc """
  ```
  iex> clean_email(" narf@narf.com.")
  "narf@narf.com"
  ```
  """
  def clean_email(eaddr) do
    eaddr
    |> String.trim()
    |> String.replace(~r/\.$/, "")
  end
end
