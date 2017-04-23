defmodule FunWithFlags.UI.Templates do
  require EEx
  alias FunWithFlags.UI.Utils
  alias FunWithFlags.Flag

  @templates ~w(_head index details new)a

  for template <- @templates do
    EEx.function_from_file :def, template, Path.expand("./templates/#{template}.html.eex", __DIR__), [:assigns]
  end


  def html_status_for(flag) do
    case Utils.get_flag_status(flag) do
      :fully_open ->
        ~s(<span class="text-success">Enabled</span>)
      :half_open ->
        ~s(<span class="text-warning">Enabled</span>)
      :closed ->
        ~s(<span class="text-danger">Disabled</span>)
    end
  end


  def html_gate_list(%Flag{gates: gates}) do
    gates
    |> Enum.map(&(&1.type))
    |> Enum.uniq()
    |> Enum.join(", ")
  end


  def path(path) do
    Utils.prefix(path)
  end
end
