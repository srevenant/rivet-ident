defmodule Rivet.Ident.Factor.Password do
  @moduledoc false
  def hash(password), do: Bcrypt.hash_pwd_salt(password)
  def verify(password, hash), do: Bcrypt.verify_pass(password, hash)
  def generate(), do: Rivet.Ident.Factor.Password.RandChars.generate()
end

defmodule Rivet.Ident.Factor.Password.Puid do
  @moduledoc """
  Puid.generate/0 is included with the `use` statement below.  It generates 18 random characters.
  """
  use Puid, total: 10.0e6, risk: 1.0e12, chars: :safe32
end

defmodule Rivet.Ident.Factor.Password.RandChars do
  @doc """
  random/0 generates a 72-character random string.
  """
  def generate(),
    do: Enum.map_join(1..4, "", fn _ -> Rivet.Ident.Factor.Password.Puid.generate() end)
end
