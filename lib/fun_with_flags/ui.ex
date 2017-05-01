defmodule FunWithFlags.UI do
  @moduledoc false

  use Application

  def start(_type, _args) do
    check_cowboy()

    children = [
      Plug.Adapters.Cowboy.child_spec(:http, FunWithFlags.UI.Router, [], [port: 8080])
    ]

    opts = [strategy: :one_for_one, name: FunWithFlags.UI.Supervisor]
    Supervisor.start_link(children, opts)
  end


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


  def run_standalone do
    Plug.Adapters.Cowboy.http FunWithFlags.UI.Router, [], port: 8080
  end


  def run_supervised do
    start(nil, nil)
  end
end
