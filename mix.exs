defmodule Remixdb.Mixfile do
  use Mix.Project

  def project do
    [app: :remixdb,
     version: "0.0.1",
     elixir: "~> 1.2",
     default_task: "remixdb",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     escript: [main_module: Remixdb.Starter],
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger]]
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
    [
      { :exredis, ">= 0.2.1" },
      {:red_black_tree, git: "https://github.com/santosh79/red_black_tree", tag: "0.1.4"}
    ]
  end
end

