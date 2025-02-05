defmodule Rivet.Auth.Token.Validation do
  alias Rivet.Auth
  alias Rivet.Ident
  require Logger

  ##############################################################################
  @spec jwt(
          target :: Ident.User.t() | Ident.Factor.t(),
          hostname :: String.t(),
          scope :: map(),
          # note: offset is used for tests only
          testing_only_expiration_offset :: nil | integer()
        ) ::
          {:ok, token :: String.t(), claims :: map(), Ident.Factor.t()}
          | {:error, String.t()}

  def jwt(target, hostname, scope \\ %{}, offset \\ 0)

  # # # # # # # # # #
  def jwt(%Ident.Factor{details: %{type: type}} = factor, hostname, scope, offset)
      when is_binary(hostname) do
    val_age = Auth.Settings.expire_limit(:val, type) + offset
    scope = %{type: type} |> Map.merge(scope)

    with {:ok, tok, claims} <-
           Auth.Token.Create.jwt(:val, "cas1:#{factor.id}", hostname, val_age, nil, scope) do
      {:ok, tok, claims, factor}
    end
  end

  # # # # # # # # # #
  def jwt(%Ident.User{} = user, hostname, scope, offset) when is_binary(hostname) do
    val_age = Auth.Settings.expire_limit(:val, :acc) + offset
    secret = Ident.Factor.Password.generate()

    # create a validation JWT
    case Ident.Factor.create(%{
           name: "valtok",
           user_id: user.id,
           type: :valtok,
           value: secret,
           details: %{type: "acc"},
           expires_at: System.os_time(:second) + val_age
         }) do
      {:ok, %Ident.Factor{} = factor} ->
        with {:ok, tok, claims, _factor} <- jwt(factor, hostname, scope, offset) do
          {:ok, tok, claims, factor}
        end

      {:error, %{errors: [expires_at: {"is invalid", _}]}} ->
        Logger.error("Unable to create Auth Token record in DB! Invalid Expiration.")
        {:error, "Invalid Expiration"}

      error ->
        Logger.error("Unable to create Auth Token record in DB! #{inspect(error)}")
        error
    end
  end

  ##############################################################################
  @spec key(hostname :: String.t(), Ident.User.t()) :: {:ok, map()} | {:error, String.t(), any()}
  def key(hostname, %Ident.User{} = user) do
    with {:ok, token, _, %Ident.Factor{value: secret}} <- jwt(user, hostname) do
      {:ok,
       %{
         sub: "cas2:#{token}",
         aud: "caa1:ref:#{hostname}",
         sec: secret,
         next: "/auth/v1/api/refresh"
       }}
    else
      err ->
        {:error, "Unable to create validaton token", err}
    end
  end
end
