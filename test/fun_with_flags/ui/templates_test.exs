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
    conn = Plug.Conn.assign(conn, :csrf_token, Plug.CSRFProtection.get_csrf_token())
    {:ok, conn: conn}
  end


  describe "url_safe" do
    test "it escapes / character" do
      assert Templates.url_safe("/") == "%2F"
    end

    test "it escapes { character" do
      assert Templates.url_safe("{") == "%7B"
    end
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
      assert String.match?(out, ~r{<a href="/pear/flags/pineapple">\n\s*pineapple\n\s*</a>})
      assert String.match?(out, ~r{<a href="/pear/flags/papaya">\n\s*papaya\n\s*</a>})
    end
  end


  describe "details()" do
    setup do
      flag = %Flag{name: :avocado, gates: []}
      {:ok, flag: flag}
    end

    test "it renders", %{conn: conn, flag: flag} do
      out = Templates.details(conn: conn, flag: flag)
      assert is_binary(out)
    end

    test "it includes the right content", %{conn: conn, flag: flag} do
      out = Templates.details(conn: conn, flag: flag)
      assert String.contains?(out, "<title>FunWithFlags - avocado</title>")
      assert String.contains?(out, ~s{<a href="/pear/new" class="btn btn-secondary">New Flag</a>})
      assert String.contains?(out, "<h1>avocado</h1>")
    end

    test "it includes the CSRF token", %{conn: conn, flag: flag} do
      csrf_token = Plug.CSRFProtection.get_csrf_token()
      out = Templates.details(conn: conn, flag: flag)
      assert String.contains?(out, ~s{<input type="hidden" name="_csrf_token" value="#{csrf_token}">})
    end

    test "it includes the global toggle, the new actor and new group forms, and the global delete form", %{conn: conn, flag: flag} do
      out = Templates.details(conn: conn, flag: flag)
      assert String.contains?(out, ~s{<form id="fwf-global-toggle-form" action="/pear/flags/avocado/boolean" method="post"})
      assert String.contains?(out, ~s{<form id="fwf-new-actor-form" action="/pear/flags/avocado/actors" method="post"})
      assert String.contains?(out, ~s{<form id="fwf-new-group-form" action="/pear/flags/avocado/groups" method="post"})
      assert String.contains?(out, ~s{<form id="fwf-delete-flag-form" action="/pear/flags/avocado" method="post">})
    end

    test "with no boolean gate, it includes both the enabled and disable boolean buttons", %{conn: conn, flag: flag} do
      out = Templates.details(conn: conn, flag: flag)
      assert String.contains?(out, ~s{<button id="enable-boolean-btn" type="submit"})
      assert String.contains?(out, ~s{<button id="disable-boolean-btn" type="submit"})
    end

    test "with an enabled boolean gate, it includes both the disable and clear boolean buttons", %{conn: conn, flag: flag} do
      f = %Flag{flag | gates: [Gate.new(:boolean, true)]}
      out = Templates.details(conn: conn, flag: f)
      assert String.contains?(out, ~s{<button id="disable-boolean-btn" type="submit"})
      assert String.contains?(out, ~s{<button id="clear-boolean-btn" type="submit"})
    end

    test "with a disabled boolean gate, it includes both the enable and clear boolean buttons", %{conn: conn, flag: flag} do
      f = %Flag{flag | gates: [Gate.new(:boolean, false)]}
      out = Templates.details(conn: conn, flag: f)
      assert String.contains?(out, ~s{<button id="enable-boolean-btn" type="submit"})
      assert String.contains?(out, ~s{<button id="clear-boolean-btn" type="submit"})
    end


    test "with no gates it reports the lists as empty", %{conn: conn, flag: flag} do
      group_gate = %Gate{type: :group, for: :rocks, enabled: true}
      actor_gate = %Gate{type: :actor, for: "moss:123", enabled: true}
      ptime_gate = %Gate{type: :percentage_of_time, for: 0.1, enabled: true}

      no_actors = %Flag{flag | gates: [group_gate, ptime_gate]}
      out = Templates.details(conn: conn, flag: no_actors)
      assert String.contains?(out, ~s{none})

      no_groups = %Flag{flag | gates: [actor_gate, ptime_gate]}
      out = Templates.details(conn: conn, flag: no_groups)
      assert String.contains?(out, ~s{none})

      no_percent = %Flag{flag | gates: [actor_gate, group_gate]}
      out = Templates.details(conn: conn, flag: no_percent)
      assert String.contains?(out, ~s{none})

      with_all = %Flag{flag | gates: [actor_gate, group_gate, ptime_gate]}
      out = Templates.details(conn: conn, flag: with_all)
      refute String.contains?(out, ~s{none})
    end

    test "with actors and groups it contains their rows", %{conn: conn, flag: flag} do
      group_gate = %Gate{type: :group, for: :rocks, enabled: true}
      actor_gate = %Gate{type: :actor, for: "moss:123", enabled: true}
      flag = %Flag{flag | gates: [actor_gate, group_gate]}

      out = Templates.details(conn: conn, flag: flag)

      assert String.contains?(out, ~s{<div id="actor_moss:123"})
      assert String.contains?(out, ~s{<form action="/pear/flags/avocado/actors/moss:123" method="post"})

      assert String.contains?(out, ~s{<div id="group_rocks"})
      assert String.contains?(out, ~s{<form action="/pear/flags/avocado/groups/rocks" method="post"})
    end

    test "with actors and groups it contains their rows with escaped HTML and URLs", %{conn: conn, flag: flag} do
      group_gate = %Gate{type: :group, for: :rocks, enabled: true}
      actor_gate = %Gate{type: :actor, for: "moss:<h1>123</h1>", enabled: true}
      flag = %Flag{flag | gates: [actor_gate, group_gate]}

      out = Templates.details(conn: conn, flag: flag)

      assert String.contains?(out, ~s{<div id="actor_moss:&lt;h1&gt;123&lt;/h1&gt;"})
      assert String.contains?(out, ~s{<form action="/pear/flags/avocado/actors/moss:%3Ch1%3E123%3C%2Fh1%3E" method="post"})

      assert String.contains?(out, ~s{<div id="group_rocks"})
      assert String.contains?(out, ~s{<form action="/pear/flags/avocado/groups/rocks" method="post"})
    end
  end


  describe "new()" do
    test "it renders", %{conn: conn} do
      out = Templates.new(conn: conn)
      assert is_binary(out)
    end

    test "it includes the right content", %{conn: conn} do
      out = Templates.new(conn: conn)
      assert String.contains?(out, "<title>FunWithFlags - New Flag</title>")
      assert String.contains?(out, ~s{<form id="new-flag-form" action="/pear/flags" method="post">})
    end
  end

  describe "not_found()" do
    test "it renders", %{conn: conn} do
      out = Templates.not_found(conn: conn, name: "watermelon")
      assert is_binary(out)
    end

    test "it includes the right content", %{conn: conn} do
      out = Templates.not_found(conn: conn, name: "watermelon")
      assert String.contains?(out, "<title>FunWithFlags - Not Found</title>")
      assert String.contains?(out, ~s{The flag <strong>watermelon</strong> doesn't exist.})
    end
  end
end
