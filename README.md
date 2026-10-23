Common Database models/code used across other Cato repos

## Migrations

Add to your project's rivet migrations.exs:

```
[
  external: :rivet_ident,
  migrations: [
    [include: "user", prefix: 100],
    [include: "handle", prefix: 110],
    [include: "email", prefix: 120],
    [include: "phone", prefix: 130],
    [include: "user/data", prefix: 140],
    [include: "user/code", prefix: 150],
    [include: "factor", prefix: 160],
    [include: "action", prefix: 170],
    [include: "role", prefix: 180],
    [include: "role/map", prefix: 190],
    [include: "access", prefix: 200],
    [include: "user/ext_id", prefix: 210]
  ]
],
```

(note: look in `rivet_ident/priv/rivet/migrations` for more details).
