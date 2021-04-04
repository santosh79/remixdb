defmodule Remixdb.Mixfile do
  use Mix.Project

  def project do
    [app: :remixdb,
     version: "0.0.3",
     elixir: "~> 1.10",
     description: "A caching library written in pure elixir",
     start_permanent: Mix.env == :prod,
     deps: deps()
    ]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [
      extra_applications: [:logger],
      env: [port: 6379],
      mod: {Remixdb, []}
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [{ :exredis, ">= 0.2.4" }]
  end
end

