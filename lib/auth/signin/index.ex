defmodule Rivet.Auth.Signin do
  alias Rivet.Auth
  alias Rivet.Ident.User
  require Logger

  @spec post_signin({:ok | :error, Auth.Domain.t()}) :: {:ok | :error, Auth.Domain.t()}
  def post_signin(%Auth.Domain{user: %User{} = u} = auth) do
    Logger.info("Signin", status: auth.status, uid: u.id)
    # TODO: events/triggers to table/signin count, etc
    {:ok, auth}
  end

  def post_signin({:ok, %Auth.Domain{} = auth}), do: post_signin(auth)
  def post_signin(pass), do: pass
end
