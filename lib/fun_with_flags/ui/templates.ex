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
    Path.join(conn.assigns[:namespace], path)
  end


  def url_safe(val) do
    val
    |> to_string()
    |> URI.encode()
  end


  @doc """
  Escape HTML using the same code that `Phoenix.HTML` uses.
  See: https://github.com/phoenixframework/phoenix_html/blob/v3.3.1/lib/phoenix_html/engine.ex#L24
  """
  def html_safe(val) when is_binary(val) do
    html_safe(val, 0, val, [])
  end

  def html_safe(val) do
    val
    |> to_string()
    |> html_safe()
  end

  escapes = [
    {?<, "&lt;"},
    {?>, "&gt;"},
    {?&, "&amp;"},
    {?", "&quot;"},
    {?', "&#39;"}
  ]

  for {match, insert} <- escapes do
    defp html_safe(<<unquote(match), rest::bits>>, skip, original, acc) do
      html_safe(rest, skip + 1, original, [acc | unquote(insert)])
    end
  end

  defp html_safe(<<_char, rest::bits>>, skip, original, acc) do
    html_safe(rest, skip, original, acc, 1)
  end

  defp html_safe(<<>>, _skip, _original, acc) do
    acc
  end

  for {match, insert} <- escapes do
    defp html_safe(<<unquote(match), rest::bits>>, skip, original, acc, len) do
      part = binary_part(original, skip, len)
      html_safe(rest, skip + len + 1, original, [acc, part | unquote(insert)])
    end
  end

  defp html_safe(<<_char, rest::bits>>, skip, original, acc, len) do
    html_safe(rest, skip, original, acc, len + 1)
  end

  defp html_safe(<<>>, 0, original, _acc, _len) do
    original
  end

  defp html_safe(<<>>, skip, original, acc, len) do
    [acc | binary_part(original, skip, len)]
  end
end
