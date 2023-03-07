import Config

config :rivet_auth,
  jwt_acc_secrets: [
    "FVMU0Uu2MqZOnT51nLi5ptNaEa+paBS7JVBhYa6KKjE="
  ],
  jwt_val_secrets: [
    "YRVkMVYlHJoxNRq2Ma1QdT1Pc8PNjo48xrObO4OgjQs="
  ],
  jwt_api_secrets: [
    "YRVkMHJdT1oxNRqVYl2Ma1QPc8PNjo48xrObO4OgjQs="
  ]

config :rivet_email,
  enabled: false,
  sender: Rivet.Email.Example
