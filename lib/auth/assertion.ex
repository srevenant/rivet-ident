defmodule Rivet.Auth.Assertion do
  @moduledoc """
  Used for standardizing auth assertion checks.

  Passed in when declaring what type of auth is needed
  """
  defstruct action: :none,
            domain: :global,
            app: nil,
            ref_id: nil,
            fallback: false

  @type t :: %__MODULE__{
          action: atom(),
          # if CXS app auth allowed, match this app
          app: nil | atom(),
          domain: Rivet.Ident.Access.Domains.t(),
          # item.id of item defined by domain
          ref_id: nil | String.t(),
          # if key above doesn't work, should we check global privs?
          fallback: boolean()
        }
end
