defmodule Rivet.Ident.Support.Auth do
  use Rivet.Ident.Support.Case
  use Rivet.Ident

  @default_opts [hostname: "example.com"]

  def user_with_auth(opts \\ @default_opts) do
    opts = Map.new(opts)
    user = insert(:ident_user)

    if not is_nil(opts[:role]), do: {:ok, _access} = Ident.Access.Lib.add(user, opts.role)

    pwd = insert(:ident_factor, user: user, type: :password)
    val = insert(:ident_factor, user: user, type: :valtok, details: %{"type" => "acc"})

    user = Factor.Lib.preloaded_with(user, [:password, :valtok])

    {:ok, Map.merge(opts, %{user: user, factor_pwd: pwd, factor_val: val})}
  end

  def user_with_access_token(opts \\ @default_opts) do
    {:ok, %{user: user} = data} = user_with_auth(opts)
    data = Map.new(opts) |> Map.merge(data)
    hostname = Keyword.get(opts, :hostname)
    %Factor{} = factor = Enum.find(user.factors, fn f -> f.type == :valtok end)
    {:ok, token, args} = Rivet.Auth.Token.Access.jwt(factor, hostname, Keyword.get(opts, :expire))
    {:ok, Map.merge(data, %{token, args})}
  end
end
