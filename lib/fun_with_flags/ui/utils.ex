defmodule FunWithFlags.UI.Utils do
  alias FunWithFlags.{Flag, Gate}


  @prefix "/"

  def prefix(path) do
    Path.join(@prefix, path)
  end


  def get_flag_status(%Flag{gates: gates}) do
    if boolean_gate_open?(gates) do
      :fully_open
    else
      if any_other_gate_open?(gates) do
        :half_open
      else
        :closed
      end
    end
  end


  defp boolean_gate_open?(gates) do
    case Enum.find(gates, &Gate.boolean?/1) do
      %Gate{enabled: enabled} -> enabled
      _ -> false
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


  # Create new flags as disabled
  #
  def create_flag_with_name(name) do
    if blank?(name) do
      {:error, "The name cannot be blank."}
    else
      name
      |> String.to_atom()
      |> FunWithFlags.disable()
    end
  end


  defp blank?(nil), do: true
  defp blank?(""), do: true
  defp blank?(" "), do: true
  defp blank?(string) when is_binary(string) do
    length = string |> String.trim |> String.length
    length == 0
  end

end
