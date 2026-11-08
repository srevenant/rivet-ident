defmodule Rivet.Ident.User.Data do
  use Rivet.Data, types: Rivet.Ident.User.Data.Types

  @impl true
  def enrich_depth(%{type: t} = d), do: enrich_depth_(t, d)
  defp enrich_depth_(:social, d), do: data_is_list(d)
  defp enrich_depth_(_, d), do: {:ok, d}
end
