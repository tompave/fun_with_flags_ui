defmodule FunWithFlagsUi.Mixfile do
  use Mix.Project

  @version "0.0.2"

  def project do
    [
      app: :fun_with_flags_ui,
      source_url: "https://github.com/tompave/fun_with_flags_ui",
      version: @version,
      elixir: "~> 1.4",
      elixirc_paths: elixirc_paths(Mix.env),
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [
      extra_applications: [:logger],
      # mod: {FunWithFlags.UI, []},
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:plug, "~> 1.3.5"},
      {:cowboy, "~> 1.1", optional: true},
      {:fun_with_flags, "~> 0.7.1"},
      {:ex_doc, ">= 0.0.0", only: :dev},
    ]
  end


  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]


  defp description do
    """
    FunWithFlags.UI, a web dashboard for the FunWithFlags Elixir package.
    """
  end

  defp package do
    [
      maintainers: [
        "Tommaso Pavese"
      ],
      licenses: [
        "MIT"
      ],
      links: %{
        "GitHub" => "https://github.com/tompave/fun_with_flags_ui",
      }
    ]
  end


  defp docs do
    [
      extras: ["README.md"],
      main: "FunWithFlags.UI",
      source_url: "https://github.com/tompave/fun_with_flags_ui/",
      source_ref: "v#{@version}"
    ]
  end
end
