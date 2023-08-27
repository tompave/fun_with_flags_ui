defmodule FunWithFlags.UI.HTMLEscape do
  @moduledoc false

  # This module contains HTML sanitization code copied from Phoenix.HTML.
  # See: https://github.com/phoenixframework/phoenix_html/blob/v3.3.1/lib/phoenix_html/engine.ex#L24

  def html_escape(bin) when is_binary(bin) do
    html_escape(bin, 0, bin, [])
  end

  def html_escape(val) do
    val
    |> to_string()
    |> html_escape()
  end

  escapes = [
    {?<, "&lt;"},
    {?>, "&gt;"},
    {?&, "&amp;"},
    {?", "&quot;"},
    {?', "&#39;"}
  ]

  for {match, insert} <- escapes do
    defp html_escape(<<unquote(match), rest::bits>>, skip, original, acc) do
      html_escape(rest, skip + 1, original, [acc | unquote(insert)])
    end
  end

  defp html_escape(<<_char, rest::bits>>, skip, original, acc) do
    html_escape(rest, skip, original, acc, 1)
  end

  defp html_escape(<<>>, _skip, _original, acc) do
    acc
  end

  for {match, insert} <- escapes do
    defp html_escape(<<unquote(match), rest::bits>>, skip, original, acc, len) do
      part = binary_part(original, skip, len)
      html_escape(rest, skip + len + 1, original, [acc, part | unquote(insert)])
    end
  end

  defp html_escape(<<_char, rest::bits>>, skip, original, acc, len) do
    html_escape(rest, skip, original, acc, len + 1)
  end

  defp html_escape(<<>>, 0, original, _acc, _len) do
    original
  end

  defp html_escape(<<>>, skip, original, acc, len) do
    [acc | binary_part(original, skip, len)]
  end
end
