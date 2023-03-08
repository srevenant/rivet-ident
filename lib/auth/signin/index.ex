defmodule Rivet.Auth.Signin do
  alias Rivet.Auth
  alias Rivet.Ident.User
  require Logger

  @spec post_signin({:ok | :error, Auth.Domain.t()}) :: {:ok | :error, Auth.Domain.t()}
  def post_signin({:ok, auth = %Auth.Domain{status: :authed, user: %User{} = u}}) do
    Logger.info("Signin Success", uid: u.id)
    # TODO: events/triggers to table/signin count, etc
    {:ok, auth}
  end

  def post_signin(pass = {:error, %Auth.Domain{}}), do: pass
end
