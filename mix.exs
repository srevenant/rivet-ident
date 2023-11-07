defmodule RivetIdent.MixProject do
  use Mix.Project

  @source_url "https://github.com/srevenant/rivet-ident"
  def project do
    [
      app: :rivet_ident,
      version: "2.7.0",
      description: "Authentication and Authorization add-on for Rivets Framework",
      source_url: @source_url,
      package: package(),
      elixir: "~> 1.14",
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
      xref: [exclude: List.wrap(Application.get_env(:rivet, :repo))],
      aliases: aliases()
    ]
  end

  def application do
    [
      mod: {Rivet.Ident.Application, []},
      env: [
        rivet: [
          app: :rivet_ident,
          base: Rivet.Ident,
          models_dir: "ident"
        ]
      ],
      extra_applications: [
        :logger,
        {:ex_unit, :optional}
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp aliases do
    [
      "ecto.setup": ["ecto.create", "rivet migrate", "ecto.migrate"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"],
      # keystrokes of life
      c: ["compile"]
    ]
  end

  defp deps do
    [
      {:absinthe, "~> 1.7.1"},
      {:bcrypt_elixir, "~> 3.0"},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:ecto_enum, "~> 1.0"},
      {:ecto_sql, "~> 3.7"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:ex_machina, "~> 2.7.0", only: :test},
      {:excoveralls, "~> 0.14", only: :test},
      {:faker, "~> 0.10"},
      {:jason, "~> 1.0"},
      {:joken, "~> 2.6.0"},
      {:jose, "~> 1.11"},
      {:junit_formatter, "~> 3.1", only: [:test]},
      {:lazy_cache, "~> 0.1.0"},
      {:mix_test_watch, "~> 1.0", only: [:test, :dev], runtime: false},
      {:postgrex, "~> 0.13"},
      {:puid, "~> 2.0"},
      {:random_password, "~> 1.1"},
      {:rivet_email, git: "https://github.com/srevenant/rivet-email/", branch: "sendto"},
      {:timex, "~> 3.6"},
      {:transmogrify, "~> 2.0.2"},
      {:typed_ecto_schema, "~> 0.3.0 or ~> 0.4.1"},
      {:yaml_elixir, "~> 2.8"}
    ]
  end

  defp package() do
    [
      files: ~w(lib .formatter.exs mix.exs priv README* LICENSE* test/lib),
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url},
      source_url: @source_url
    ]
  end
end
