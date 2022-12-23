defmodule RivetDataIdent.MixProject do
  use Mix.Project

  def project do
    [
      app: :rivet_data_ident,
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
      rivet: [
        mod_dir: "ident",
        # there is a better way, but for now I want to just get it working
        ensure_loaded: [:rivet_data_ident]
      ],
      aliases: aliases()
    ]
  end

  def application do
    [
      mod: {Rivet.Data.Ident.Application, []},
      extra_applications: [
        :rivet,
        :rivet_email,
        :logger,
        :postgrex,
        :ecto,
        :timex,
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
      {:rivet, "~> 1.0.0", git: "git@github.com:srevenant/rivet", branch: "master"},
      {:rivet_utils, "~> 1.0.0"},
      {:rivet_email, "~> 1.0.0", git: "git@github.com:srevenant/rivet-email", branch: "master"},
      {:ecto_sql, "~> 3.7"},
      {:ecto_enum, "~> 1.0"},
      {:excoveralls, "~> 0.14", only: :test},
      {:ex_machina, "~> 2.7.0", only: :test},
      {:bcrypt_elixir, "~> 1.1.1"},
      {:puid, "~> 2.0"},
      # {:ex_doc, "~> 0.18", only: :dev, runtime: false},
      {:faker, "~> 0.10"},
      {:postgrex, "~> 0.13"},
      {:yaml_elixir, "~> 2.8.0"},
      {:jason, "~> 1.0"},
      {:mix_test_watch, "~> 0.8", only: [:test, :dev], runtime: false},
      {:timex, "~> 3.6"},
      {:lazy_cache, "~> 0.1.0"},
      {:typed_ecto_schema, "~> 0.3.0 or ~> 0.4.1"},
      {:junit_formatter, "~> 3.1", only: [:test]},
      {:random_password, "~> 1.1"}
    ]
  end

  defp package() do
    [
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*),
      licenses: ["AGPL-3.0-or-later"],
      links: %{"GitHub" => "https://github.com/srevenant/atom-data-auth"},
      source_url: "https://github.com/srevenant/atom-data-auth"
    ]
  end
end
