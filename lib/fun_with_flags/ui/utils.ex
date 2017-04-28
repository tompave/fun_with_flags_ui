defmodule FunWithFlags.UI.Utils do
  alias FunWithFlags.{Flag, Gate}


  def get_flag_status(%Flag{gates: gates} = flag) do
    if boolean_gate_open?(flag) do
      :fully_open
    else
      if any_other_gate_open?(gates) do
        :half_open
      else
        :closed
      end
    end
  end

  defp boolean_gate_open?(flag) do
    Flag.enabled?(flag)
  end

  defp any_other_gate_open?(gates) do
    gates
    |> Enum.filter(fn(gate) -> !Gate.boolean?(gate) end)
    |> Enum.any?(fn(%Gate{enabled: enabled}) -> enabled end)
  end


  def sort_flags(flags) do
    Enum.sort(flags, &sorter/2)
  end

  defp sorter(a, b) do
    sa = get_flag_status(a)
    sb = get_flag_status(b)

    if sa == sb do
      a.name < b.name
    else
      case sa do
        :fully_open -> true
        :half_open ->
          case sb do
            :fully_open -> false
            :closed -> true
          end
        :closed -> false
      end
    end
  end


  # Create new flags as disabled
  #
  def create_flag_with_name(name) do
    name
    |> String.to_atom()
    |> FunWithFlags.disable()
  end


  def get_flag(name) do
    {:ok, flag} = FunWithFlags.SimpleStore.lookup(String.to_atom(name))
    flag
  end


  def blank?(nil), do: true
  def blank?(""), do: true
  def blank?(" "), do: true
  def blank?(string) when is_binary(string) do
    length = string |> String.trim |> String.length
    length == 0
  end


  def boolean_gate(%Flag{gates: gates}) do
    Enum.find(gates, &Gate.boolean?/1)
  end

  def actor_gates(%Flag{gates: gates}) do
    gates
    |> Enum.filter(&Gate.actor?/1)
    |> Enum.sort_by(&(&1.for))
  end

  def group_gates(%Flag{gates: gates}) do
    gates
    |> Enum.filter(&Gate.group?/1)
    |> Enum.sort_by(&(&1.for))
  end


  def parse_bool("true"), do: true
  def parse_bool("1"), do: true
  def parse_bool(1), do: true
  def parse_bool(_), do: false


  def validate_flag_name(conn, name) do
    if Regex.match?(~r/^\w+$/, name) do
      if flag_exists?(name) do
        path = Path.join(conn.assigns[:namespace], "/flags/" <> name)
        {:fail, "A flag named '#{name}' <u><a href='#{path}' class='text-danger'>already exists</a></u>."}
      else
        :ok
      end
    else
      {:fail, "Invalid flag name, it must match <code>/^\w+$/</code>."}
    end
  end


  defp flag_exists?(name) do
    {:ok, all} = FunWithFlags.all_flag_names
    this = String.to_atom(name)
    Enum.member?(all, this)
  end

  def sanitize(name) do
    name
    |> String.trim()
  end

  def validate(name) do
    string = to_string(name)
    cond do
      blank?(string) ->
        {:fail, "can't be blank" }
      String.match?(string, ~r/\?/) ->
        {:fail, "includes invalid characters: '?'"}
      true ->
        :ok
    end
  end
end
