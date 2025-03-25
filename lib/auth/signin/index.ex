defmodule Rivet.Auth.Signin do
  alias Rivet.Auth
  alias Rivet.Ident.User
  require Logger

  @spec post_signin({:ok | :error, Auth.Domain.t()}) :: {:ok | :error, Auth.Domain.t()}
  def post_signin({:ok, %Auth.Domain{user: %User{} = u} = auth}) do
    Logger.info("Signin", status: auth.status, uid: u.id)
    # TODO: events/triggers to table/signin count, etc
    {:ok, auth}
  end

  def post_signin(pass = {:error, %Auth.Domain{}}), do: pass

  # DRY
  def create_user(<<handle::binary>>, <<eaddr::binary>>, <<hostname::binary>>, type, input \\ %{})
      when is_atom(type) do
    User.Lib.Signup.signup(
      %Auth.Domain{
        hostname: hostname,
        input:
          Map.merge(input, %{
            handle: handle,
            email: %{address: eaddr, verified: false}
          })
      },
      type
    )
  end
end
