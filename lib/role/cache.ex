defmodule Cato.Data.Auth.Role.Cache do
  use ADI.Utils.LazyCache, bucket_key: :rcache_bucket, keyset_key: :rcache_keyset
end
