defmodule FunWithFlags.UI.TestUser do
  defstruct [:id]
end

defimpl FunWithFlags.Actor, for: FunWithFlags.UI.TestUser do
  def id(%{id: id}) do
    "user:#{id}"
  end
end
