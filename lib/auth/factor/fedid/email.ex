defmodule Rivet.Data.Auth.Factor.FedId.Email do
  defstruct address: "",
            verified: false

  @type t :: %__MODULE__{
          address: String.t(),
          verified: boolean
        }
end
