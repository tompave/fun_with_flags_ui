defmodule FunWithFlags.UI.Utils do
  @moduledoc false

  alias FunWithFlags.{Flag, Gate}


  def get_flag_status(%Flag{gates: gates} = flag) do
    case boolean_gate_open?(flag) do
      {:ok, true} ->
        :fully_open
      _ ->
        if any_other_gate_open?(gates) do
          :half_open
        else
          :closed
        end
    end
  end

  def boolean_gate_open?(%Flag{gates: gates}) do
    case Enum.find(gates, &Gate.boolean?/1) do
      %Gate{type: :boolean, enabled: enabled} ->
        {:ok, enabled}
      nil ->
        :missing
    end
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


  # Create new flags as disabled.
  #
  # Here we are converting a user-provided string to an atom, which is
  # potentially dangerous because atoms are not garbage collected.
  # Since we're going to persist it, however, the idea is that it's going
  # to be used anyway, and to be fair filling the persistent store with
  # unneeded data is a bigger concern.
  #
  def create_flag_with_name(name) do
    name
    |> String.to_atom()
    |> FunWithFlags.disable()
  end


  def get_flag(name) do
    if safe_flag_exists?(name) do
      case FunWithFlags.SimpleStore.lookup(String.to_existing_atom(name)) do
        {:ok, _flag} = result ->
          result
        {:error, _reason} = error ->
          error
      end
    else
      {:error, "not found"}
    end
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
  def parse_bool(true), do: true
  def parse_bool(_), do: false


  def validate_flag_name(conn, name) do
    if Regex.match?(~r/^\w+$/, name) do
      if safe_flag_exists?(name) do
        path = Path.join(conn.assigns[:namespace], "/flags/" <> name)
        {:fail, "A flag named '#{name}' <u><a href='#{path}' class='text-danger'>already exists</a></u>."}
      else
        :ok
      end
    else
      {:fail, "Invalid flag name, it must match <code>/^\w+$/</code>."}
    end
  end


  # We don't want to just convert any user provided string to an atom because
  # atoms are not garbage collected, and this could potentially leak memory
  # if some endpoint was abused and hammered with random non-existing flag names.
  #
  # Getting the list of the current flag names will reference and create all the
  # current atoms, and then `String.to_existing_atom/1` will simply raise an
  # error if the name doesn't match any existing atom. That implicitly proves
  # that there is no flag for that name
  #
  defp safe_flag_exists?(name) do
    try do
      {:ok, all} = FunWithFlags.all_flag_names()
      Enum.member?(all, String.to_existing_atom(name))
    rescue
      ArgumentError -> false
    end
  end


  def sanitize(name) do
    name
    |> String.trim()
  end

  def validate(name) do
    string = to_string(name)
    cond do
      blank?(string) ->
        {:fail, "can't be blank"}
      String.match?(string, ~r/\?/) ->
        {:fail, "includes invalid characters: '?'"}
      true ->
        :ok
    end
  end
end
