defmodule Rivet.Ident.MixProject do
  use Mix.Project

  @source_url "https://github.com/srevenant/rivet-ident"
  def project do
    [
      app: :rivet_ident,
      version: "5.1.0",
      elixir: "~> 1.18",
      description: "Authentication and Authorization add-on for Rivets Framework",
      source_url: @source_url,
      docs: docs(),
      package: package(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.html": :test,
        dialyzer: :test
      ],
      dialyzer: [
        ignore_warnings: ".dialyzer_ignore.exs",
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
      ],
      elixirc_paths: elixirc_paths(Mix.env()),
      xref: [exclude: List.wrap(Application.get_env(:rivet, :repo))],
      aliases: aliases(),
      compilers: [:es6_maps | Mix.compilers()]
    ]
  end

  def application do
    [
      mod: {Rivet.Ident.Application, []},
      env: [rivet: [app: :rivet_ident, base: Rivet.Ident, models_dir: "ident"]],
      # NOTE: :inets is required for :httpd_util.convert_request_date to not
      # throw a warning in static compile verification from OTP
      extra_applications: [:logger, :inets]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support", "test/fixtures"]
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
      {:absinthe, ">= 1.7.0 and < 2.0.0"},
      {:bcrypt_elixir, "~> 3.3"},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:es6_maps, "~> 1.0.2"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:ex_machina, "~> 2.7", only: :test},
      {:excoveralls, "~> 0.18", only: :test},
      {:faker, "~> 0.18", only: [:dev, :test]},
      {:jason, "~> 1.4"},
      {:joken, "~> 2.6"},
      {:jose, "~> 1.11"},
      {:mix_test_watch, "~> 1.4", only: [:dev, :test], runtime: false},
      {:puid, "~> 2.3"},
      {:random_password, "~> 1.2"},
      # {:rivet, "~> 2.7"},
      {:rivet, git: "https://github.com/srevenant/rivet/", branch: "mailer-updates"},
      {:transmogrify, "~> 2.0.2"},
      # {:typed_ecto_schema, "~> 0.4.1"},
      {:yaml_elixir, "~> 2.8"}
    ]
  end

  defp package() do
    [
      files: ~w(lib .formatter.exs mix.exs README* LICENSE* priv/rivet test/fixtures),
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp docs(), do: [main: "Rivet.Ident", extras: ["README.md"]]
end
