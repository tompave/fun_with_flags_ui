defmodule FunWithFlags.UI.Templates do
  @moduledoc false

  require EEx
  alias FunWithFlags.Flag
  alias FunWithFlags.UI.Utils

  @templates [
    _head: "_head",
    index: "index",
    details: "details",
    new: "new",
    not_found: "not_found",
    _boolean_row: "rows/_boolean",
    _actor_row: "rows/_actor",
    _group_row: "rows/_group",
    _percentage_row: "rows/_percentage",
    _new_actor_row: "rows/_new_actor",
    _new_group_row: "rows/_new_group",
    _percentage_form_row: "rows/_percentage_form",
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

  def html_status_for({:ok, bool}) do
    html_status_for(bool)
  end

  def html_status_for(:missing) do
    ~s{<span class="badge badge-default">Disabled (missing)</span>}
  end

  def html_status_for(bool) when is_boolean(bool) do
    if bool do
      ~s(<span class="badge badge-success">Enabled</span>)
    else
      ~s(<span class="badge badge-danger">Disabled</span>)
    end
  end

  @gate_type_order [
    :boolean,
    :actor,
    :group,
    :percentage_of_actors,
    :percentage_of_time,
  ]
  |> Enum.with_index()
  |> Map.new()

  def html_gate_list(%Flag{gates: gates}) do
    gates
    |> Enum.map(&(&1.type))
    |> Enum.uniq()
    |> Enum.sort_by(&Map.get(@gate_type_order, &1, 99))
    |> Enum.join(", ")
  end


  def path(conn, path) do
    Path.join(base_path(conn), path)
  end


  # https://github.com/thoughtbot/bamboo/blob/master/lib/bamboo/plug/sent_email_viewer/email_preview_plug.ex#L107
  def base_path(%{script_name: []}), do: ""

  def base_path(%{script_name: script_name}) do
    "/" <> Enum.join(script_name, "/")
  end
end
