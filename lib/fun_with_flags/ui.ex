defmodule FunWithFlags.UI do
  @moduledoc false

  alias FunWithFlags.UI.Router

  def start do
    Application.ensure_started(:fun_with_flags)
    Plug.Adapters.Cowboy.http Router, [], port: 8080
  end
end
