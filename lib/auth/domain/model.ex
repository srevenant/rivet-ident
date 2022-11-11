defmodule Rivet.Data.Auth.Domain do
  alias Rivet.Data.Auth

  defstruct type: :acc,
            status: :unknown,
            tenant: nil,
            user: nil,
            app: nil,
            email: nil,
            handle: nil,
            token: nil,
            factor: nil,
            created: false,
            log: nil,
            error: nil,
            input: nil,
            expires: 0

  @type t :: %Auth.Domain{
          type: atom,
          status: atom,
          tenant: nil | Auth.Tenant.t(),
          user: nil | Auth.User.t(),
          app: nil | String.t(),
          handle: nil | Auth.UserHandle.t(),
          email: nil | Auth.UserEmail.t(),
          factor: nil | Auth.Factor.t(),
          token: nil | map,
          created: boolean,
          # log is what we save in the logs
          log: nil | String.t(),
          # error is what we send users (default: Signin Failed)
          error: nil | String.t(),
          input: nil | map,
          expires: integer
        }
end
