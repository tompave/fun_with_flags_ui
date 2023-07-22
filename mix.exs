defmodule FunWithFlagsUi.Mixfile do
  use Mix.Project

  @version "0.8.1"

  def project do
    [
      app: :fun_with_flags_ui,
      source_url: "https://github.com/tompave/fun_with_flags_ui",
      version: @version,
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env),
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
    ]
  end


  # The most common use case for this library is to embed it in
  # a host web application and serve it from a sub path: it should
  # just be plug'ed into a Phoenix or Plug router.
  # In that case, there is no need to start :fun_with_flags_ui as
  # its own application, as the Router plug will be managed as a simpl
  # termination plug for the host's HTTP handler.
  #
  # The commented out `mod: {}` configuration, below, is provided just
  # as _an example_ of what it would be needed to run :fun_with_flags_ui
  # fully standalone.
  #
  def application do
    [
      extra_applications: [:logger],
      # mod: {FunWithFlags.UI, []},
    ]
  end


  defp deps do
    [
      {:plug, "~> 1.12"},
      {:plug_cowboy, ">= 2.0.0", optional: true},
      {:cowboy, ">= 2.0.0", optional: true},
      {:fun_with_flags, "~> 1.8"},
      {:redix, "~> 1.0", only: [:dev, :test]},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:credo, "~> 1.6", only: :dev, runtime: false},
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
      main: "readme",
      source_url: "https://github.com/tompave/fun_with_flags_ui/",
      source_ref: "v#{@version}"
    ]
  end
end
