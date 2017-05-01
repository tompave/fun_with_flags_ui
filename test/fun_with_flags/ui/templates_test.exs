defmodule FunWithFlags.UI.TemplatesTest do
  use ExUnit.Case, async: true

  alias FunWithFlags.UI.Templates
  alias FunWithFlags.{Flag, Gate}

  import FunWithFlags.UI.TestUtils

  setup_all do
    on_exit(__MODULE__, fn() -> clear_redis_test_db() end)
    :ok
  end

  setup do
    conn = Plug.Conn.assign(%Plug.Conn{}, :namespace, "/pear")
    {:ok, conn: conn}
  end


  describe "_head()" do
    test "it renders", %{conn: conn} do
      out = Templates._head(conn: conn, title: "Coconut")
      assert is_binary(out)
    end

    test "it includes the right content", %{conn: conn} do
      out = Templates._head(conn: conn, title: "Coconut")
      assert String.contains?(out, "<title>FunWithFlags - Coconut</title>")
      assert String.contains?(out, ~s{href="/pear/assets/style.css"})
    end
  end


  describe "index()" do
    setup do
      flags = [
        %Flag{name: :pineapple, gates: [Gate.new(:boolean, true)]},
        %Flag{name: :papaya, gates: [Gate.new(:boolean, false)]},
      ]
      {:ok, flags: flags}
    end

    test "it renders", %{conn: conn, flags: flags} do
      out = Templates.index(conn: conn, flags: flags)
      assert is_binary(out)
    end

    test "it includes the right content", %{conn: conn, flags: flags} do
      out = Templates.index(conn: conn, flags: flags)
      assert String.contains?(out, "<title>FunWithFlags - List</title>")
      assert String.contains?(out, ~s{<a href="/pear/new" class="btn btn-secondary">New Flag</a>})
      assert String.contains?(out, ~s{<a href="/pear/flags/pineapple">pineapple</a>})
      assert String.contains?(out, ~s{<a href="/pear/flags/papaya">papaya</a>})
    end
  end
end
