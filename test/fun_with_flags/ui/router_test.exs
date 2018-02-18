defmodule FunWithFlags.UI.RouterTest do
  use ExUnit.Case, async: false
  use Plug.Test
  import FunWithFlags.UI.TestUtils

  alias FunWithFlags.UI.Router
  alias FunWithFlags.{Flag, Gate}

  setup_all do
    on_exit(__MODULE__, fn() -> clear_redis_test_db() end)
    :ok
  end

  @opts Router.init([])

  describe "GET /" do
    test "redirects to /flags" do
      conn = request!(:get, "/")
      assert 302 = conn.status
      assert ["/flags"] = get_resp_header(conn, "location")
    end
  end


  describe "GET /new" do
    test "responds with HTML" do
      conn = request!(:get, "/flags")
      assert 200 = conn.status
      assert is_binary(conn.resp_body)
      assert ["text/html; charset=utf-8"] = get_resp_header(conn, "content-type")
    end
  end

  describe "POST /flags" do
    test "with valid parameters it creates the flag and redirects to its page" do
      refute Enum.member?(elem(FunWithFlags.all_flag_names, 1), :mango)
      conn = request!(:post, "/flags", %{flag_name: "mango"})
      assert Enum.member?(elem(FunWithFlags.all_flag_names, 1), :mango)

      assert 302 = conn.status
      assert ["/flags/mango"] = get_resp_header(conn, "location")
    end

    test "with invalid parameters it re-renders the page" do
      initially = FunWithFlags.all_flag_names
      conn = request!(:post, "/flags", %{flag_name: ""})
      assert ^initially = FunWithFlags.all_flag_names # no changes

      assert 400 = conn.status
      assert is_binary(conn.resp_body)
      assert ["text/html; charset=utf-8"] = get_resp_header(conn, "content-type")
    end


    test "with valid parameters but a name that is already in use it re-renders the page" do
      {:ok, true} = FunWithFlags.enable :papaya
      assert Enum.member?(elem(FunWithFlags.all_flag_names, 1), :papaya)

      initially = FunWithFlags.all_flag_names
      conn = request!(:post, "/flags", %{flag_name: "papaya"})
      assert ^initially = FunWithFlags.all_flag_names # no changes

      assert 400 = conn.status
      assert is_binary(conn.resp_body)
      assert ["text/html; charset=utf-8"] = get_resp_header(conn, "content-type")
    end
  end


  describe "GET /flags" do
    test "responds with HTML" do
      conn = request!(:get, "/flags")
      assert 200 = conn.status
      assert is_binary(conn.resp_body)
      assert ["text/html; charset=utf-8"] = get_resp_header(conn, "content-type")
    end

    test "when some flags exist, the response contains their names" do
      name = unique_atom()
      FunWithFlags.enable(name)

      conn = request!(:get, "/flags")
      assert String.contains?(conn.resp_body, to_string(name))
    end
  end


  describe "GET /flags/:name" do
    test "when the flag exists, it responds the the details page" do
      {:ok, true} = FunWithFlags.enable :coconut

      conn = request!(:get, "/flags/coconut")
      assert 200 = conn.status
      assert is_binary(conn.resp_body)
      assert ["text/html; charset=utf-8"] = get_resp_header(conn, "content-type")
    end

    test "when the flag doesn't exists, it responds the the details page" do
      conn = request!(:get, "/flags/#{unique_atom()}")
      assert 404 = conn.status
      assert is_binary(conn.resp_body)
      assert ["text/html; charset=utf-8"] = get_resp_header(conn, "content-type")
    end
  end


  describe "DELETE /flags/:name/boolean" do
    test "when the flag exists, it deletes its boolean gate and redirects to the flag page" do
      {:ok, true} = FunWithFlags.enable :frozen_yogurt
      {:ok, true} = FunWithFlags.enable :frozen_yogurt, for_group: "some_group" 

      assert %Flag{name: :frozen_yogurt, gates: [%Gate{type: :boolean}, %Gate{type: :group}]} = FunWithFlags.get_flag(:frozen_yogurt)

      conn = request!(:delete, "/flags/frozen_yogurt/boolean")
      assert 302 = conn.status
      assert ["/flags/frozen_yogurt"] = get_resp_header(conn, "location")

      assert %Flag{name: :frozen_yogurt, gates: [%Gate{type: :group}]} = FunWithFlags.get_flag(:frozen_yogurt)
    end
  end


  describe "DELETE /flags/:name/percentage" do
    test "when the flag exists, it deletes its current percentage gate and redirects to the flag page" do
      {:ok, true} = FunWithFlags.enable :pizza, for_percentage_of: {:time, 0.5}
      {:ok, true} = FunWithFlags.enable :pizza, for_group: "some_group" 

      assert %Flag{name: :pizza, gates: [%Gate{type: :percentage_of_time, for: 0.5}, %Gate{type: :group}]} = FunWithFlags.get_flag(:pizza)

      conn = request!(:delete, "/flags/pizza/percentage")
      assert 302 = conn.status
      assert ["/flags/pizza"] = get_resp_header(conn, "location")

      assert %Flag{name: :pizza, gates: [%Gate{type: :group}]} = FunWithFlags.get_flag(:pizza)
    end
  end


  # For GET and DELETE
  #
  defp request!(method, path) do
    conn(method, path)
    |> Router.call(@opts)
  end

  # For POST and PATCH
  #
  # Do a little dance to URL-encode the body rather than just
  # passing a Map, because that's what the HTML forms do.
  # Using a map here would require to add the :multipart
  # parser to the Router just for the tests.
  #
  defp request!(method, path, params) when is_map(params) do
    conn(method, path, Plug.Conn.Query.encode(params))
    |> put_req_header("content-type", "application/x-www-form-urlencoded")
    |> Router.call(@opts)
  end
end
