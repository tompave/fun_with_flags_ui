defmodule FunWithFlags.UI.SimpleActor do
  @moduledoc false

  defstruct [:id]
end

# Simply return the unchanged ID.
# This is useful because all the function in the
# public API of FunWithFlags expect actors.
#
defimpl FunWithFlags.Actor, for: FunWithFlags.UI.SimpleActor do
  def id(%{id: id}), do: id
end
