defmodule Rivet.Ident.Email.Lib do
  use Rivet.Ident
  import Ecto.Query

  def has_verified?(%User{emails: [%{verified: true}]}), do: true

  def has_verified?(%User{id}) do
    from(e in Email, where: e.user_id == ^id and e.verified)
    |> Repo.exists?()
  end

  def clean_email(eaddr) do
    eaddr
    |> String.trim()
    |> String.replace(~r/\.$/, "")
  end
end
