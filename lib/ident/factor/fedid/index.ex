defmodule Rivet.Data.Ident.Factor.FedId do
  @moduledoc """
  Structure for in-process authentication result contexts, not directly to one user
  """
  alias __MODULE__

  # see enums for Ident.FactorNums -- this is any federated type
  defstruct name: nil,
            handle: nil,
            email: %__MODULE__.Email{},
            phone: nil,
            settings: %{locale: "en"},
            provider: %__MODULE__.Provider{}

  @type t :: %__MODULE__{
          name: nil | String.t(),
          handle: nil | String.t(),
          email: __MODULE__.Email.t(),
          phone: nil | String.t(),
          settings: map,
          provider: __MODULE__.Provider.t()
        }
end
