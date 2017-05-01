defmodule FunWithFlags.UI do
  @moduledoc """
  FunWithFlags.UI, a Web dashboard for the [FunWithFlags](https://github.com/tompave/fun_with_flags) package.

  See the [Readme](/fun_with_flags_ui/readme.html#how-to-run) for more detailed instructions.
  """

  use Application

  @doc false
  def start(_type, _args) do
    check_cowboy()

    children = [
      Plug.Adapters.Cowboy.child_spec(:http, FunWithFlags.UI.Router, [], [port: 8080])
    ]

    opts = [strategy: :one_for_one, name: FunWithFlags.UI.Supervisor]
    Supervisor.start_link(children, opts)
  end


  # Since :cowboy is an optional dependency, if we want to run this
  # standalone we want to return a clear error message if Cowboy is
  # missing.
  #
  # On the other hand, if :fun_with_flags_ui is run as a Plug in a
  # host application, we don't really care about this dependency
  # here, as the responsibility of managing the HTTP layer belongs
  # to the host app.
  #
  defp check_cowboy do
    with :ok <- Application.ensure_started(:ranch),
         :ok <- Application.ensure_started(:cowlib),
         :ok <- Application.ensure_started(:cowboy) do
      :ok
    else
      {:error, _} ->
        raise "You need to add :cowboy to your Mix dependencies to run FunWithFlags.UI standalone."
    end
  end


  @doc """
  Convenience function to simply run the Plug in Cowboy.

  This _will_ be supervided, but in the private supervsion tree
  of :cowboy and :ranch.
  """#"""
  def run_standalone do
    Plug.Adapters.Cowboy.http FunWithFlags.UI.Router, [], port: 8080
  end


  @doc """
  Convenience function to run the Plug in a custom supervision tree.

  This is just an example. If you actually need this, you might want
  to use your own supervision setup.
  """
  def run_supervised do
    start(nil, nil)
  end
end
