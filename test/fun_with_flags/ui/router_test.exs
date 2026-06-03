defmodule FunWithFlags.UI.RouterTest do
  use ExUnit.Case, async: false
  import Plug.Test
  import Plug.Conn
  import FunWithFlags.UI.TestUtils

  alias FunWithFlags.UI.Router
  alias FunWithFlags.{Flag, Gate}

  setup do
    clear_redis_test_db()
    :ok
  end

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



  describe "POST /flags/:name/percentage" do
    test "with no previous percentage gate it creates a new one, then redirects to the details page" do
      {:ok, false} = FunWithFlags.disable :chocolate

      assert %Flag{name: :chocolate, gates: [%Gate{type: :boolean}]} = FunWithFlags.get_flag(:chocolate)

      conn = request!(:post, "/flags/chocolate/percentage", %{
        percent_type: "time",
        percent_value: "0.5"
      })
      assert 302 = conn.status
      assert ["/flags/chocolate#percentage_gate"] = get_resp_header(conn, "location")

      assert %Flag{name: :chocolate, gates: [
        %Gate{type: :boolean},
        %Gate{type: :percentage_of_time, for: 0.5},
      ]} = FunWithFlags.get_flag(:chocolate)
    end

    test "with a previous percentage gate it replaces it, then redirects to the details page" do
      {:ok, false} = FunWithFlags.disable :chocolate
      {:ok, true} = FunWithFlags.enable :chocolate, for_percentage_of: {:time, 0.99}

      assert %Flag{name: :chocolate, gates: [
        %Gate{type: :boolean},
        %Gate{type: :percentage_of_time, for: 0.99},
      ]} = FunWithFlags.get_flag(:chocolate)

      conn = request!(:post, "/flags/chocolate/percentage", %{
        percent_type: "time",
        percent_value: "0.5"
      })
      assert 302 = conn.status
      assert ["/flags/chocolate#percentage_gate"] = get_resp_header(conn, "location")

      assert %Flag{name: :chocolate, gates: [
        %Gate{type: :boolean},
        %Gate{type: :percentage_of_time, for: 0.5},
      ]} = FunWithFlags.get_flag(:chocolate)
    end


    test "with invalid params, it renders the details page with errors" do
      {:ok, false} = FunWithFlags.disable :chocolate

      conn = request!(:post, "/flags/chocolate/percentage", %{
        percent_type: "time",
        percent_value: " "
      })
      assert 400 = conn.status
      assert is_binary(conn.resp_body)
      assert ["text/html; charset=utf-8"] = get_resp_header(conn, "content-type")
      assert String.contains?(conn.resp_body, "The percentage value can't be blank.")
    end
  end


  # Simulates a host application (for example, a Phoenix `:browser` pipeline)
  # that runs `Plug.CSRFProtection` *around* the forwarded router. The host's
  # CSRF plug registers a `before_send` callback that raises
  # `InvalidCrossOriginRequestError` for non-XHR `GET`s returning JavaScript.
  # The router must suppress that for its own assets so the dashboard loads.
  describe "embedded under a host CSRF pipeline" do
    @session_opts Plug.Session.init(
                    store: :cookie,
                    key: "_test_session",
                    signing_salt: "test-salt",
                    encryption_salt: "test-enc"
                  )
    @csrf_opts Plug.CSRFProtection.init([])

    defp through_host_csrf(conn) do
      conn
      |> Map.put(:secret_key_base, String.duplicate("a", 64))
      |> Plug.Session.call(@session_opts)
      |> fetch_session()
      |> Plug.CSRFProtection.call(@csrf_opts)
      |> Router.call(@opts)
    end

    test "a JavaScript asset loads without raising InvalidCrossOriginRequestError" do
      conn = through_host_csrf(conn(:get, "/assets/details.js"))

      assert conn.status == 200
      assert conn.private[:plug_skip_csrf_protection] == true
      # `Plug.Static` serves `.js` as `text/javascript`, which is exactly the
      # content type the host's CSRF `before_send` callback would reject.
      assert ["text/javascript"] = get_resp_header(conn, "content-type")
    end

    test "a CSS asset loads as well" do
      conn = through_host_csrf(conn(:get, "/assets/style.css"))

      assert conn.status == 200
      assert conn.private[:plug_skip_csrf_protection] == true
    end

    test "an HTML page is served normally and is not opted out of CSRF" do
      conn = through_host_csrf(conn(:get, "/flags"))

      assert conn.status == 200
      refute conn.private[:plug_skip_csrf_protection]
    end

    test "a forged state-changing request is still rejected" do
      # No `_csrf_token`, so the host CSRF plug rejects it before the router
      # can act, and the asset skip never applies to mutations.
      assert_raise Plug.CSRFProtection.InvalidCSRFTokenError, fn ->
        through_host_csrf(conn(:post, "/flags", "flag_name=nope"))
      end
    end
  end


  describe "asset CSRF skip" do
    test "is set only for safe methods on /assets/<file>" do
      for method <- [:get, :head] do
        conn = conn(method, "/assets/details.js") |> Router.call(@opts)
        assert conn.private[:plug_skip_csrf_protection] == true,
               "expected #{method} /assets/details.js to be skipped"
      end
    end

    test "is not set for non-asset paths" do
      for path <- ["/flags", "/new", "/"] do
        conn = conn(:get, path) |> Router.call(@opts)
        refute conn.private[:plug_skip_csrf_protection],
               "expected #{path} to retain CSRF protection"
      end
    end

    test "is not set for the bare /assets path with no file" do
      conn = conn(:get, "/assets") |> Router.call(@opts)
      refute conn.private[:plug_skip_csrf_protection]
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
