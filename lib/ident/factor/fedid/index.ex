defmodule Rivet.Data.Ident.Factor.FedId do
  @moduledoc """
  Structure for in-process authentication result contexts, not directly to one user
  """
  # alias __MODULE__

  # see enums for Ident.FactorNums -- this is any federated type
  defstruct name: nil,
            handle: nil,
            email: %Rivet.Data.Ident.Factor.FedId.Email{},
            phone: nil,
            settings: %{locale: "en"},
            provider: %Rivet.Data.Ident.Factor.FedId.Provider{}

  @type t :: %__MODULE__{
          name: nil | String.t(),
          handle: nil | String.t(),
          email: Rivet.Data.Ident.Factor.FedId.Email.t(),
          phone: nil | String.t(),
          settings: map,
          provider: Rivet.Data.Ident.Factor.FedId.Provider.t()
        }
end
