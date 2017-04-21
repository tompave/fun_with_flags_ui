defmodule FunWithFlags.UI.Templates do
  require EEx
  alias FunWithFlags.UI.Utils

  @templates ~w(_head index details)a

  for template <- @templates do
    EEx.function_from_file :def, template, Path.expand("./templates/#{template}.html.eex", __DIR__), [:assigns]
  end
end
