defmodule Rivet.Auth.Domain do
  @moduledoc """
  Structure for in-process authentication result contexts, not directly to one user
  """
  alias Rivet.Ident

  defstruct type: :acc,
            status: :unknown,
            authz: %{},
            hostname: nil,
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

  @type t :: %__MODULE__{
          type: atom,
          status: atom,
          authz: map,
          hostname: nil | String.t(),
          app: nil | String.t(),
          user: nil | Ident.User.t(),
          handle: nil | Ident.Handle.t(),
          email: nil | Ident.Email.t(),
          factor: nil | Ident.Factor.t(),
          token: nil | map,
          created: boolean,
          # log is what we save in the logs
          log: nil | String.t(),
          # error is what we send users (default: Signin Failed)
          error: nil | String.t(),
          input: nil | map,
          expires: integer
        }

  @type result :: {:ok | :error, t()}
end
