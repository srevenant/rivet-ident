defmodule Rivet.Auth.Token do
  # Break out the claims of a JWT, without any validation
  @doc """
  iex> jwt = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJjYWExOmFjYzpleGFtcGxlLmNvbSIsImV4cCI6MTY3MTkyMjMwMCwiZm9yIjp7fSwic3ViIjoiY2FzMTpuYXJmIn0.N6PV_XAGTjymi1CEfVkKRj433S0XBlTxcevL7VAhTRY"
  iex> extract(jwt, :all)
  {:ok, %{"alg" => "HS256","typ" => "JWT"}, %{aud: "caa1:acc:example.com", exp: 1671922300, for: %{}, sub: "cas1:narf"}}
  iex> extract(jwt, :claims)
  {:ok, %{aud: "caa1:acc:example.com", exp: 1671922300, for: %{}, sub: "cas1:narf"}}
  iex> extract(jwt, :header)
  {:ok, %{"alg" => "HS256","typ" => "JWT"}}
  iex> extract("asdf", :all)
  {:error, "Invalid JWT, cannot extract claims"}
  iex> extract("asdf.asdf.asdf", :all)
  {:error, "Unable to decode JWT part: asdf"}
  """

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
