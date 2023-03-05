defmodule Rivet.Auth.Token.Create do
  import Rivet.Auth.Settings

  @doc """
  iex> {:ok, _tok, claims} = jwt(:acc, "narf", "NARF", 10, "narf", %{})
  iex> claims.aud
  "caa1:acc:NARF"
  """
  def jwt(type, subject, hostname, exp \\ nil, secret \\ nil, scope \\ %{}, claims \\ %{})

  def jwt(type, subject, hostname, nil, secret, scope, claims),
    do: jwt(type, subject, hostname, expire_limit(type), secret, scope, claims)

  def jwt(type, subject, hostname, exp, nil, scope, claims),
    do: jwt(type, subject, hostname, exp, current_jwt_secret(type), scope, claims)

  def jwt(type, subject, hostname, exp, secret, scope, claims)
      when is_binary(hostname) and is_binary(subject) and (is_binary(secret) or is_list(secret)) and
             type in [:acc, :ref, :val] and
             is_integer(exp) do
    signer = Joken.Signer.create("HS256", secret)

    claims =
      Map.merge(
        %{
          "sub" => subject,
          "aud" => "caa1:#{type}:#{hostname}",
          "exp" => System.os_time(:second) + exp,
          "for" => scope
        },
        Transmogrify.transmogrify(claims, key_convert: :string)
      )

    # not sure why this step was required previously, but it's getting grief
    # from dialyzer
    # with {:ok, claims} <- Joken.generate_claims(%{}, claims),
    with {:ok, token, claims} <- Joken.encode_and_sign(claims, signer) do
      {:ok, token, Transmogrify.transmogrify(claims)}
    end
  end
end
