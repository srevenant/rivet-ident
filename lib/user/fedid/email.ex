defmodule Cato.Data.Auth.User.FedIdEmail do
  defstruct address: "",
            verified: false

  @type t :: %__MODULE__{
          address: String.t(),
          verified: boolean
        }
end
