defmodule FunWithFlags.UI.Templates do
  @moduledoc false

  require EEx
  alias FunWithFlags.UI.Utils
  alias FunWithFlags.Flag

  @templates [
    _head: "_head",
    index: "index",
    details: "details",
    new: "new",
    not_found: "not_found",
    _boolean_row: "rows/_boolean",
    _actor_row: "rows/_actor",
    _group_row: "rows/_group",
    _new_actor_row: "rows/_new_actor",
    _new_group_row: "rows/_new_group",
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
      ~s(<span class="badge badge-success">Enabled</span>)
    else
      ~s(<span class="badge badge-danger">Disabled</span>)
    end
  end


  def html_gate_list(%Flag{gates: gates}) do
    gates
    |> Enum.map(&(&1.type))
    |> Enum.uniq()
    |> Enum.join(", ")
  end

  def gate_alias({_, target_alias}), do: target_alias
  def gate_alias(target), do: target

  def gate_for({target_for, _}), do: target_for
  def gate_for(target), do: target

  def path(conn, path) do
    Path.join(conn.assigns[:namespace], path)
  end
end
