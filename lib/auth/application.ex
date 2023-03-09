defmodule Rivet.Auth.Application do
  use Application

  def start(_type, _args) do
    Rivet.Auth.Settings.start()

    children = [Rivet.Ident.Factor.Cache]

    children =
      if Application.get_env(:rivet_ident, :federated, %{}).google do
        [
          {Rivet.Auth.Signin.Google.KeyManager, %{interval: 4_000}}
          | children
        ]
      else
        children
      end

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
