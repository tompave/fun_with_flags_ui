defmodule FunWithFlags.UI.FlagTransform do
  def flag_with_aliases(flag) do
    gates = Enum.map(flag.gates, &gate_aliases/1)
    %{flag | gates: gates}
  end

  defp gate_aliases(%{for: "user:" <> id} = gate) do
    %{gate | for: {"user:#{id}", "User #{id}"}}
  end
  defp gate_aliases(gate), do: gate
end
