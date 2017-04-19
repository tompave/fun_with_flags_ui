defmodule FunWithFlags.UI.Utils do
  alias FunWithFlags.{Flag, Gate}

  def html_status_for(flag) do
    case get_status(flag) do
      :fully_open ->
        ~s(<span class="text-success">Enabled</span>)
      :half_open ->
        ~s(<span class="text-warning">Enabled</span>)
      :closed ->
        ~s(<span class="text-danger">Disabled</span>)
    end
  end


  def get_status(%Flag{gates: gates}) do
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


  def sort(flags) do
    Enum.sort(flags, &sorter/2)
  end

  defp sorter(a, b) do
    sa = get_status(a)
    sb = get_status(b)

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

end
