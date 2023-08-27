defmodule FunWithFlags.UI.HTMLEscapeTest do
  use ExUnit.Case, async: true
  import FunWithFlags.UI.HTMLEscape, only: [html_escape: 1]

  describe "html_escape/1" do
    test "it HTML-escapes the input" do
      assert "&lt;div&gt;" = to_string(html_escape("<div>"))
      assert "&lt;div&gt;1&amp;2&lt;/div&gt;" = to_string(html_escape("<div>1&2</div>"))
      assert "one &lt;div&gt;1&amp;2&lt;/div&gt; two" = to_string(html_escape("one <div>1&2</div> two"))
      assert(
        "one &lt;div&gt;1&amp;2&lt;/div&gt; two &quot;and &#39;three&#39;!&quot;" =
          to_string(html_escape(~s{one <div>1&2</div> two "and 'three'!"}))
      )
    end
  end
end
