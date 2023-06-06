[
  [include: "user_ident", prefix: 210],
  [include: "access", prefix: 200],
  [include: "role_map", prefix: 190],
  [include: "role", prefix: 180],
  [include: "action", prefix: 170],
  [include: "factor", prefix: 160],
  [include: "user_code", prefix: 150],
  [include: "user_data", prefix: 140],
  [include: "phone", prefix: 130],
  [include: "email", prefix: 120],
  [include: "handle", prefix: 110],
  [include: "user", prefix: 100],
  [
    external: :rivet_email,
    migrations: [
      [include: "template", prefix: 220]
    ]
  ]
]
