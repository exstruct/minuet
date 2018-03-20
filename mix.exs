defmodule Minuet.MixProject do
  use Mix.Project

  def project do
    [
      app: :minuet,
      version: "0.1.0",
      elixir: "~> 1.6",
      description: "hypermedia api toolkit",
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.travis": :test,
        "coveralls.detail": :test,
        "coveralls.html": :test
      ],
      package: package(),
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications:
        case Mix.env() do
          :prod ->
            []

          _ ->
            [:poison, :msgpax]
        end
    ]
  end

  defp deps do
    [
      {:poison, "~> 3.1", optional: true},
      {:msgpax, "~> 2.1", optional: true},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:rl, "~> 0.1", only: :dev, runtime: false},
      {:excoveralls, "~> 0.8", only: :test},
      {:dialyzex, "~> 1.1.0", only: :dev},
      {:stream_data, "~> 0.4.2", only: :test},
      {:benchee, github: "PragTob/benchee", only: :test}
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README*"],
      maintainers: ["Cameron Bytheway"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/exstruct/minuet"}
    ]
  end
end
