defmodule Cato.Data.Auth.User.FedId do
  @moduledoc """
  Structure for in-process authentication result contexts, not directly to one user
  """
  # alias __MODULE__

  # see enums for Auth.FactorNums -- this is any federated type
  defstruct name: nil,
            handle: nil,
            email: %Cato.Data.Auth.User.FedIdEmail{},
            phone: nil,
            settings: %{locale: "en"},
            provider: %Cato.Data.Auth.User.FedIdProvider{}

  @type t :: %__MODULE__{
          name: nil | String.t(),
          handle: nil | String.t(),
          email: Cato.Data.Auth.User.FedIdEmail.t(),
          phone: nil | String.t(),
          settings: map,
          provider: Cato.Data.Auth.User.FedIdProvider.t()
        }
end
