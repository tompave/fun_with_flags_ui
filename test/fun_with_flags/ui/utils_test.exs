defmodule FunWithFlags.UI.UtilsTest do
  use ExUnit.Case, async: true

  alias FunWithFlags.UI.Utils
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
      flag = %Flag{name: :pineapple, gates: [Gate.new(:boolean, false)]}
      assert :closed = Utils.get_flag_status(flag)
    end

    test "with a flag without any gate it returns :closed" do
      flag = %Flag{name: :pineapple, gates: []}
      assert :closed = Utils.get_flag_status(flag)
    end

    test "with a partially enabled flag it returns :half_open" do
      flag = %Flag{name: :pineapple, gates: [Gate.new(:group, :people, true)]}
      assert :half_open = Utils.get_flag_status(flag)
    end
  end

  describe "boolean_gate_open?(flag)" do
    test "with a globally enabled flag it returns {:ok, true}" do
      flag = %Flag{name: :pineapple, gates: [Gate.new(:boolean, true)]}
      assert {:ok, true} = Utils.boolean_gate_open?(flag)
    end

    test "with a globally disabled flag it returns {:ok, false}" do
      flag = %Flag{name: :pineapple, gates: [Gate.new(:boolean, false)]}
      assert {:ok, false} = Utils.boolean_gate_open?(flag)
    end

    test "with a flag without boolean gate it returns :missing" do
      flag = %Flag{name: :pineapple, gates: [Gate.new(:group, :people, true)]}
      assert :missing = Utils.boolean_gate_open?(flag)
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
      p1 = %Gate{type: :percentage_of_time, for: 0.42, enabled: true}

      flag = %Flag{name: unique_atom(), gates: [a1, g2, b0, a2, g1, p1]}
      {:ok, flag: flag, b0: b0, a1: a1, a2: a2, g1: g1, g2: g2, p1: p1}
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


    test "percentage_gate(flag)", %{flag: flag, p1: p1} do
      assert ^p1 = Utils.percentage_gate(flag)
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

    test "it returns {:fail, reason} for values with URI reserved characters" do
      assert {:fail, "includes URI reserved characters"} = Utils.validate(:banana?)
      assert {:fail, "includes URI reserved characters"} = Utils.validate(:"ban/ana")
      assert {:fail, "includes URI reserved characters"} = Utils.validate(:"ban#ana")
      assert {:fail, "includes URI reserved characters"} = Utils.validate(:"ban&ana")
    end

    test "it returns :ok otherwise" do
      assert :ok = Utils.validate(:foo_bar_CiaoCiao)
    end
  end

  describe "parse_and_validate_float(float_string)" do
    test "it rejects blanks" do
      assert {:fail, "can't be blank"} = Utils.parse_and_validate_float("")
      assert {:fail, "can't be blank"} = Utils.parse_and_validate_float(" ")
      assert {:fail, "can't be blank"} = Utils.parse_and_validate_float("   ")
      assert {:fail, "can't be blank"} = Utils.parse_and_validate_float("\n")
    end

    test "it rejects invalid strings" do
      assert {:fail, "is not a valid decimal number"} = Utils.parse_and_validate_float("a")
      assert {:fail, "is not a valid decimal number"} = Utils.parse_and_validate_float("foo")
      assert {:fail, "is not a valid decimal number"} = Utils.parse_and_validate_float("bar0.11")
    end

    test "it rejects floats smaller than equal to 0 or larger than or equal to 1" do
      assert {:fail, "is outside the '0.0 < x < 1.0' range"} = Utils.parse_and_validate_float("0")
      assert {:fail, "is outside the '0.0 < x < 1.0' range"} = Utils.parse_and_validate_float("0.0")
      assert {:fail, "is outside the '0.0 < x < 1.0' range"} = Utils.parse_and_validate_float("1")
      assert {:fail, "is outside the '0.0 < x < 1.0' range"} = Utils.parse_and_validate_float("1.0")
      assert {:fail, "is outside the '0.0 < x < 1.0' range"} = Utils.parse_and_validate_float("-2")
      assert {:fail, "is outside the '0.0 < x < 1.0' range"} = Utils.parse_and_validate_float("11")
      assert {:fail, "is outside the '0.0 < x < 1.0' range"} = Utils.parse_and_validate_float("-2.5")
      assert {:fail, "is outside the '0.0 < x < 1.0' range"} = Utils.parse_and_validate_float("-0.01")
      assert {:fail, "is outside the '0.0 < x < 1.0' range"} = Utils.parse_and_validate_float("1.01")
    end

    test "it parses and returns valid floats" do
      assert {:ok, 0.1} = Utils.parse_and_validate_float("0.1")
      assert {:ok, 0.1} = Utils.parse_and_validate_float("0.1000")
      assert {:ok, 0.999999999} = Utils.parse_and_validate_float("0.999999999")
      assert {:ok, 0.54} = Utils.parse_and_validate_float("0.54")
    end
  end


  describe "parse_percentage_type(string)" do
    test "it parses and symbolizes the known types" do
      assert :time = Utils.parse_percentage_type("time")
      assert :actors = Utils.parse_percentage_type("actors")
    end

    test "it converts unknown values to the default 'time'" do
      assert :time = Utils.parse_percentage_type("foobar")
      assert :time = Utils.parse_percentage_type("")
    end
  end

  describe "as_percentage(float)" do
    test "it returns float * 100 without rounding errors" do
      assert 42.1337 = Utils.as_percentage(0.421337) # 42.133700000000005
      assert 12.3457 = Utils.as_percentage(0.123457) # 12.345699999999999
      assert 10.0 = Utils.as_percentage(0.1)
      assert 1.5 = Utils.as_percentage(0.015)
      assert 99.0 = Utils.as_percentage(0.99)
      assert 11.45 = Utils.as_percentage(0.1145)
    end
  end
end
