defmodule Exonerate.MixProject do
  use Mix.Project

  def project do
    [
      app: :exonerate,
      version: "0.2.2",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      package: [
        description: "JSON Schema macro generator",
        licenses: ["MIT"],
        files: ~w(lib mix.exs README* LICENSE* VERSIONS*),
        links: %{"GitHub" => "https://github.com/ityonemo/exonerate"}
      ],
      source_url: "https://github.com/ityonemo/exonerate/",
      docs: [main: "Exonerate"],
      preferred_cli_env: [bench_lib: :bench]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  def elixirc_paths(:test), do: ["lib", "test/support"]
  def elixirc_paths(:bench), do: ["lib", "bench"]
  def elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:match_spec, "~> 0.3.1"},
      {:json_ptr, "~> 0.5"},
      {:jason, "~> 1.4.0"},
      # optional dependencies
      {:req, "~> 0.3", optional: true},
      {:finch, "~> 0.15", optional: true},
      {:yaml_elixir, "~> 2.7", optional: true},
      # dev tools
      {:ex_doc, "~> 0.24", only: :dev},
      {:dialyxir, "~> 1.2.0", only: :dev, runtime: false},
      # test
      {:bandit, "~> 0.7", only: :test},
      # benchmarking tools
      {:ex_json_schema, "~> 0.9.2", only: :bench},
      {:json_xema, "~> 0.3", only: :bench},
      {:benchee, "~> 1.1.0", only: :bench}
    ]
  end
end
