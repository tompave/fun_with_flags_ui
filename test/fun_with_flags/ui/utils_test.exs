defmodule FunWithFlags.UI.UtilsTest do
  use ExUnit.Case, async: true

  alias FunWithFlags.UI.Utils
  alias FunWithFlags.UI.TestUser
  alias FunWithFlags.{Flag, Gate}

  import FunWithFlags.UI.TestUtils

  setup_all do
    on_exit(__MODULE__, fn() -> clear_redis_test_db() end)
    :ok
  end

  describe "get_flag_status(flag)" do
    test "with a globally enabled flag it returns :fully_open" do
      flag = %Flag{name: :pineapple, gates: [Gate.new(:boolean, true)]}
      assert :fully_open = Utils.get_flag_status(flag)
    end

    test "with a globally disabled flag it returns :closed" do
      flag = %Flag{name: :pineapple, gates: []}
      assert :closed = Utils.get_flag_status(flag)
    end

    test "with a partially enabled flag it returns :half_open" do
      flag = %Flag{name: :pineapple, gates: [Gate.new(:group, :people, true)]}
      assert :half_open = Utils.get_flag_status(flag)
    end
  end


  describe "sort_flags(flags)" do
    test "it sorts the flag by status, then by name" do
      a = %Flag{name: :aaa, gates: [Gate.new(:group, :people, true)]}
      b = %Flag{name: :bbb, gates: []}
      c = %Flag{name: :ccc, gates: [Gate.new(:group, :people, true)]}
      d = %Flag{name: :ddd, gates: [Gate.new(:boolean, true)]}
      e = %Flag{name: :eee, gates: []}
      f = %Flag{name: :fff, gates: [Gate.new(:group, :people, true)]}
      g = %Flag{name: :ggg, gates: [Gate.new(:boolean, true)]}
      h = %Flag{name: :hhh, gates: []}
      i = %Flag{name: :iii, gates: [Gate.new(:boolean, true)]}

      input  = [i, h, g, f, e, d, c, b, a]
      output = [d, g, i, a, c, f, b, e, h]

      assert ^output = Utils.sort_flags(input)
    end
  end


  describe "create_flag_with_name(name)" do
    test "it creates a disabled flag" do
      clear_redis_test_db()

      name = unique_atom()
      assert {:ok, []} = FunWithFlags.all_flag_names()
      refute FunWithFlags.enabled?(name)

      assert {:ok, false} = Utils.create_flag_with_name(to_string(name))

      assert {:ok, [^name]} = FunWithFlags.all_flag_names()
      refute FunWithFlags.enabled?(name)
    end
  end


  describe "get_flag(name)" do
    test "it returns {:error, \"not found\"} for non existing flags" do
      name = unique_atom()
      assert {:error, "not found"} = Utils.get_flag(to_string(name))
    end

    test "it returns {:ok, flag} for exsisting flags" do
      name = unique_atom()
      FunWithFlags.enable(name, for_group: :berries)

      gate = Gate.new(:group, :berries, true)
      assert {:ok, %Flag{name: ^name, gates: [^gate]}} = Utils.get_flag(to_string(name))
    end

    test "it transforms actor aliases" do
      name = unique_atom()
      FunWithFlags.enable(name, for_actor: %TestUser{id: 123})

      gate = %Gate{type: :actor, for: {"user:123", "User 123"}, enabled: true}
      assert {:ok, %Flag{name: ^name, gates: [^gate]}} = Utils.get_flag(to_string(name))
    end
  end


  describe "blank?(something)" do
    test "nil is blank" do
      assert Utils.blank?(nil)
    end

    test "an empty string is blank" do
      assert Utils.blank?("")
    end

    test "a blank string is blank" do
      assert Utils.blank?(" ")
      assert Utils.blank?("       ")
      assert Utils.blank?("  
       ")
    end

    test "a string with something else in it is not blank" do
      refute Utils.blank?("a")
    end
  end


  describe "the gate filters" do
    setup do
      b0 = Gate.new(:boolean, true)
      g1 = Gate.new(:group, :animals, true)
      g2 = Gate.new(:group, :people, true)
      a1 = %Gate{type: :actor, for: "actor:aaa", enabled: true}
      a2 = %Gate{type: :actor, for: "actor:bbb", enabled: true}

      flag = %Flag{name: unique_atom(), gates: [a1, g2, b0, a2, g1]}
      {:ok, flag: flag, b0: b0, a1: a1, a2: a2, g1: g1, g2: g2}
    end

    test "boolean_gate(flag)", %{flag: flag, b0: b0} do
      assert ^b0 = Utils.boolean_gate(flag)
    end


    test "actor_gates(flag)", %{flag: flag, a1: a1, a2: a2} do
      assert [^a1, ^a2] = Utils.actor_gates(flag)
    end


    test "group_gates(flag)", %{flag: flag, g1: g1, g2: g2} do
      assert [^g1, ^g2] = Utils.group_gates(flag)
    end
  end


  describe "parse_bool(something)" do
    test "true values" do
      assert Utils.parse_bool("true")
      assert Utils.parse_bool("1")
      assert Utils.parse_bool(1)
      assert Utils.parse_bool(true)
    end

    test "false values" do
      refute Utils.parse_bool("false")
      refute Utils.parse_bool("0")
      refute Utils.parse_bool(0)
      refute Utils.parse_bool(false)
      refute Utils.parse_bool("anything else, really")
    end
  end


  describe "validate_flag_name(conn, name)" do
    setup do
      conn = Plug.Conn.assign(%Plug.Conn{}, :namespace, "/")
      {:ok, conn: conn}
    end
    test "returns :ok for a valid name", %{conn: conn} do
      assert :ok = Utils.validate_flag_name(conn, "foo_bar")
    end

    test "returns {:fail, reason} for an invalid name", %{conn: conn} do
      assert {:fail, reason} = Utils.validate_flag_name(conn, "foo bar")
      assert String.starts_with?(reason, "Invalid flag name, it must match")
    end

    test "returns {:fail, reason} for a name that is already in use", %{conn: conn} do
      name = unique_atom()
      {:ok, true} = FunWithFlags.enable(name)

      assert {:fail, reason} = Utils.validate_flag_name(conn, to_string(name))
      assert String.starts_with?(reason, "A flag named '#{name}'")
    end
  end


  describe "sanitize(name)" do
    test "it removes leading and trailing whitespace" do
      assert "apricot" = Utils.sanitize(" apricot   ")
    end
  end


  describe "validate(name)" do
    test "it returns {:fail, reason} for blank values" do
      assert {:fail, "can't be blank"} = Utils.validate(:"")
    end

    test "it returns {:fail, reason} for values with question marks" do
      assert {:fail, "includes invalid characters: '?'"} = Utils.validate(:banana?)
    end

    test "it returns :ok otherwise" do
      assert :ok = Utils.validate(:foo_bar_CiaoCiao)
    end
  end
end
