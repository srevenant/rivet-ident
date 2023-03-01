defmodule Rivet.Auth.Signin do
  alias Rivet.Auth.Domain
  alias Rivet.Data.Ident.User
  require Logger

  @spec post_signin({:ok | :error, Domain.t()}) :: {:ok | :error, Domain.t()}
  def post_signin({:ok, auth = %Domain{status: :authed, user: %User{} = u}}) do
    Logger.info("Signin Success", uid: u.id)
    # TODO: events/triggers to table/signin count, etc
    {:ok, auth}
  end

  def post_signin(pass = {:error, %Domain{}}), do: pass
end
