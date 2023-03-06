defmodule Rivet.Auth.Token.Cxs do
  alias Rivet.Auth.Settings
  alias Rivet.Auth.Token
  alias Rivet.Data.Ident

  def jwt(app, hostname) do
    case Map.get(Settings.getcfg(:cxs_apps, %{}), String.to_atom(app)) do
      nil ->
        {:error, "Invalid / unconfigured cxs application '#{app}'"}

      %{secrets: [secret | _]} = cfg ->
        exp = Settings.expire_limit(:cxs)

        with {:ok, claims} =
               Joken.generate_claims(%{}, %{
                 "sub" => "cas1:#{app}",
                 "aud" => "caa1:cxs:#{hostname}",
                 "exp" => System.os_time(:second) + exp,
                 "for" => %{}
               }) do
          signer = Joken.Signer.create("HS256", secret)

          with {:ok, jwt, claims} = Joken.encode_and_sign(claims, signer) do
            {:ok, "#{cfg.index} #{jwt}", claims}
          end
        end
    end
  end
end
