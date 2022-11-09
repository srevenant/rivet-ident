defmodule Cato.Data.Adi.MixProject do
  use Mix.Project

  def project do
    [
      app: :cato_data_auth,
      version: "2.0.0",
      package: package(),
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.html": :test
      ],
      deps: deps(),
      dialyzer: [
        ignore_warnings: ".dialyzer_ignore.exs",
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
      ],
      # lockfile: "../../mix.lock",
      aliases: aliases()
      # xref: [exclude: [AuthX.ApiKey, AuthX.Settings, AuthX.Token.Requests]]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :postgrex, :ecto, :timex, {:ex_unit, :optional}]
      # mod: {Cato.Data.Adi.Application, []}
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "core.seeds"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"],
      # "ecto.seeds": ["core.seeds"],
      c: ["compile"]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:cato_data, "~> 1.0.0", git: "git@github.com:catodigital/cato-data", branch: "noisy"},
      {:unify, "~> 1.0.0", git: "git@github.com:srevenant/unify", branch: "master"},
      {:adi_schema, "~> 3.2.0", repo: "cato"},
      {:adi_utils, "~> 1.4.0", repo: "cato"},
      # {:adi_databus, "~> 1.1.0", repo: "cato"},
      {:ecto_sql, "~> 3.7"},
      {:ecto_enum, "~> 1.0"},
      {:excoveralls, "~> 0.14", only: :test},
      {:ex_machina, "~> 2.7.0", only: :test},
      # {:ex_doc, "~> 0.18", only: :dev, runtime: false},
      {:faker, "~> 0.10"},
      {:postgrex, "~> 0.13"},
      {:yaml_elixir, "~> 2.8.0"},
      {:jason, "~> 1.0"},
      {:mix_test_watch, "~> 0.8", only: [:test, :dev], runtime: false},
      {:timex, "~> 3.6"},
      # {:csv, "~> 2.3"},
      {:lazy_cache, "~> 0.1.0"},
      {:typed_ecto_schema, "~> 0.3.0 or ~> 0.4.1"},
      # {:deep_merge, "~> 1.0"},
      {:junit_formatter, "~> 3.1", only: [:test]}
      # {:random_password, "~> 1.1"}
    ]
  end

  defp package() do
    [
      files: ~w(lib test/support .formatter.exs mix.exs README*),
      organization: "cato",
      links: %{homepage: "https://cato.digital"},
      licenses: ["Copyright Cato Digital, Inc."]
    ]
  end
end
