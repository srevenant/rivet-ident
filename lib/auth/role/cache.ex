defmodule Rivet.Data.Auth.Role.Cache do
  use Rivet.Utils.LazyCache, bucket_key: :rcache_bucket, keyset_key: :rcache_keyset
end
