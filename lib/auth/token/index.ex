defmodule Rivet.Auth.Token do
  def extract(token, part \\ :claims)

  def extract(token, :claims) do
    case String.split(token, ".", parts: 3) do
      [_, claims, _] -> decode_part_atomkeys(claims)
      _ -> {:error, "Invalid JWT, cannot extract claims"}
    end
  end

  def extract(token, :header) do
    case String.split(token, ".", parts: 2) do
      [header, _] -> decode_part(header)
      _ -> {:error, "Invalid JWT, cannot extract claims"}
    end
  end

  def extract(token, :all) do
    case String.split(token, ".", parts: 3) do
      [header, claims, _] ->
        with {:ok, header} <- decode_part(header),
             {:ok, claims} <- decode_part_atomkeys(claims) do
          {:ok, header, claims}
        end

      _ ->
        {:error, "Invalid JWT, cannot extract claims"}
    end
  end

  def decode_part(encoded) do
    with {:ok, data} <- Base.url_decode64(encoded, padding: false),
         {:ok, claims} <- Jason.decode(data) do
      {:ok, claims}
    else
      _ -> {:error, "Unable to decode JWT part: #{encoded}"}
    end
  end

  @doc """
  Warning with using this: trust the encoded segment keys as this creates atoms.
  """
  def decode_part_atomkeys(encoded) do
    with {:ok, claims} <- decode_part(encoded),
         do: {:ok, Transmogrify.transmogrify(claims)}
  end
end
