defmodule FunWithFlags.UI.Router do
  use Plug.Router
  alias FunWithFlags.UI.{Templates, Utils}

  plug Plug.Logger, log: :debug

  plug Plug.Static,
    gzip: true,
    at: "/assets",
    from: Path.expand("./assets/", __DIR__)

  plug Plug.Parsers, parsers: [:urlencoded]
  plug Plug.MethodOverride

  plug :match
  plug :dispatch

  get "/" do
    conn
    |> redirect_to("/flags")
  end


  get "/new" do
    conn
    |> html_resp(200, Templates.new(%{}))
  end

  post "/flags" do
    name = conn.params["flag_name"]

    case Utils.create_flag_with_name(name) do
      {:error, reason} ->
        conn
        |> html_resp(400, Templates.new(%{error_message: reason}))
      {:ok, _} ->
        redirect_to conn, "/flags/#{name}"
    end
  end


  get "/flags" do
    {:ok, flags} = FunWithFlags.all_flags
    flags = Utils.sort_flags(flags)
    body = Templates.index(flags: flags)

    conn
    |> html_resp(200, body)
  end


  get "/flags/:name" do
    {:ok, flag} = FunWithFlags.SimpleStore.lookup(String.to_atom(name))
    body = Templates.details(flag: flag)
    
    conn
    |> html_resp(200, body)
  end


  patch "/flags/:name/boolean" do
    enabled = Utils.parse_bool(conn.params["enabled"])
    flag_name = String.to_atom(name)
    gate = FunWithFlags.Gate.new(:boolean, enabled)

    FunWithFlags.Config.store_module.put(flag_name, gate)
    redirect_to conn, "/flags/#{name}"
  end

  patch "/flags/:name/actors/:actor_id" do
    enabled = Utils.parse_bool(conn.params["enabled"])
    flag_name = String.to_atom(name)
    gate = %FunWithFlags.Gate{type: :actor, for: actor_id, enabled: enabled}

    FunWithFlags.Config.store_module.put(flag_name, gate)
    redirect_to conn, "/flags/#{name}"
  end

  patch "/flags/:name/groups/:group_id" do
    enabled = Utils.parse_bool(conn.params["enabled"])
    flag_name = String.to_atom(name)
    gate = %FunWithFlags.Gate{type: :group, for: group_id, enabled: enabled}

    FunWithFlags.Config.store_module.put(flag_name, gate)
    redirect_to conn, "/flags/#{name}"
  end


  post "/flags/:name/actors" do
    flag_name = String.to_atom(name)
    actor_id = conn.params["actor_id"]
    enabled = Utils.parse_bool(conn.params["enabled"])
    gate = %FunWithFlags.Gate{type: :actor, for: actor_id, enabled: enabled}

    FunWithFlags.Config.store_module.put(flag_name, gate)
    redirect_to conn, "/flags/#{name}"
  end


  post "/flags/:name/groups" do
    flag_name = String.to_atom(name)
    group_name = conn.params["group_name"]
    enabled = Utils.parse_bool(conn.params["enabled"])
    gate = %FunWithFlags.Gate{type: :group, for: group_name, enabled: enabled}

    FunWithFlags.Config.store_module.put(flag_name, gate)
    redirect_to conn, "/flags/#{name}"
  end


  match _ do
    send_resp(conn, 404, "")
  end


  defp html_resp(conn, status, body) do
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(status, body)
  end


  defp redirect_to(conn, uri) do
    path = Utils.prefix(uri)

    conn
    |> put_resp_header("location", path)
    |> put_resp_content_type("text/html")
    |> send_resp(302, "<html><body>You are being <a href=\"#{path}\">redirected</a>.</body></html>")
  end
end
