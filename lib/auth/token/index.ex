defmodule Rivet.Auth.Token do
  def extract(token, part \\ :claims)

  def extract(token, :claims) do
    case String.split(token, ".", parts: 3) do
      [_, claims, _] -> decode_part(claims, true)
      _ -> {:error, "Invalid JWT, cannot extract claims"}
    end
  end

  def extract(token, :header) do
    case String.split(token, ".", parts: 2) do
      [header, _] -> decode_part(header, false)
      _ -> {:error, "Invalid JWT, cannot extract claims"}
    end
  end

  def extract(token, :all) do
    case String.split(token, ".", parts: 3) do
      [header, claims, _] ->
        with {:ok, header} <- decode_part(header, false),
             {:ok, claims} <- decode_part(claims, true) do
          {:ok, header, claims}
        end

      _ ->
        {:error, "Invalid JWT, cannot extract claims"}
    end
  end

  defp decode_part(data, as_atom) do
    case {Base.decode64!(data, padding: false) |> Jason.decode(), as_atom} do
      {{:ok, claims}, true} -> {:ok, Transmogrify.transmogrify(claims)}
      {{:ok, claims}, false} -> {:ok, claims}
      {{:error, _msg}, _} -> {:error, "Unable to decode JWT part: #{data}"}
    end
  end
end
