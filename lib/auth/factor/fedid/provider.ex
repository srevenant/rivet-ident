defmodule Rivet.Data.Auth.Factor.FedId.Provider do
  defstruct type: :unknown,
            kid: nil,
            jti: nil,
            iss: nil,
            iat: nil,
            exp: 0,
            azp: nil,
            aud: nil,
            token: nil

  @type t :: %__MODULE__{
          type: atom,
          kid: nil | String.t(),
          jti: nil | String.t(),
          iss: nil | String.t(),
          iat: nil | String.t(),
          exp: 0 | integer,
          azp: nil | String.t(),
          aud: nil | String.t(),
          token: nil | String.t()
        }
end
