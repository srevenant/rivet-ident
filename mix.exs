defmodule RivetAuth.MixProject do
  use Mix.Project

  def project do
    [
      app: :rivet_auth,
      version: "2.0.0",
      package: package(),
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.html": :test,
        dialyzer: :test
      ],
      deps: deps(),
      dialyzer: [
        ignore_warnings: ".dialyzer_ignore.exs",
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
      ],
      rivet: [
        mod_dir: "ident",
        app_base: Rivet.Data.Ident
      ],
      aliases: aliases()
    ]
  end

  def application do
    [
      mod: {Rivet.Auth.Application, []},
      extra_applications: [
        :logger,
        {:ex_unit, :optional}
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp aliases do
    [
      # , "rivet.data.seeds"],
      "ecto.setup": ["ecto.create", "ecto.migrate"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"],
      # keystrokes of life
      c: ["compile"]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:rivet, "~> 1.0.0", git: "git@github.com:IslandUsurper/rivet", branch: "db2lib"},
       {:rivet_email, "~> 1.0.0", git: "git@github.com:IslandUsurper/rivet-email", branch: "cfg"},
      {:rivet_utils, "~> 1.0.0", git: "git@github.com:IslandUsurper/rivet-utils", branch: "start-cache", override: true},
      # {:rivet_utils, "~> 1.0.0"},
      {:bcrypt_elixir, "~> 1.1.1"},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:ecto_enum, "~> 1.0"},
      {:ecto_sql, "~> 3.7"},
      {:faker, "~> 0.10"},
      {:jason, "~> 1.0"},
      {:joken, "~> 2.6.0"},
      {:jose, "~> 1.11.5"},
      {:lazy_cache, "~> 0.1.0"},
      {:postgrex, "~> 0.13"},
      {:puid, "~> 2.0"},
      {:random_password, "~> 1.1"},
      {:timex, "~> 3.6"},
      {:transmogrify, "~> 1.1.0", override: true},
      {:typed_ecto_schema, "~> 0.3.0 or ~> 0.4.1"},
      {:yaml_elixir, "~> 2.8.0"},
      # {:ex_doc, "~> 0.18", only: :dev, runtime: false},
      {:excoveralls, "~> 0.14", only: :test},
      {:ex_machina, "~> 2.7.0", only: :test},
      {:junit_formatter, "~> 3.1", only: [:test]},
      {:mix_test_watch, "~> 0.8", only: [:test, :dev], runtime: false}
    ]
  end

  defp package() do
    [
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*),
      licenses: ["AGPL-3.0-or-later"],
      links: %{"GitHub" => "https://github.com/srevenant/rivet-data-ident"},
      source_url: "https://github.com/srevenant/rivet-data-ident"
    ]
  end
end
