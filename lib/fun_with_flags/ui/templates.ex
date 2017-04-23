defmodule FunWithFlags.UI.Templates do
  require EEx
  alias FunWithFlags.UI.Utils
  alias FunWithFlags.Flag

  @templates [
    _head: "_head",
    index: "index",
    details: "details",
    new: "new",
    _boolean_row: "rows/_boolean",
    _actor_row: "rows/_actor",
    _group_row: "rows/_group",
    _new_actor_row: "rows/_new_actor",
  ]

  for {fn_name, file_name} <- @templates do
    EEx.function_from_file :def, fn_name, Path.expand("./templates/#{file_name}.html.eex", __DIR__), [:assigns]
  end


  def html_smart_status_for(flag) do
    case Utils.get_flag_status(flag) do
      :fully_open ->
        ~s(<span class="text-success">Enabled</span>)
      :half_open ->
        ~s(<span class="text-warning">Enabled</span>)
      :closed ->
        ~s(<span class="text-danger">Disabled</span>)
    end
  end


  def html_status_for(bool) do
    if bool do
      ~s(<span class="text-success font-weight-bold">Enabled</span>)
    else
      ~s(<span class="text-danger font-weight-bold">Disabled</span>)
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
