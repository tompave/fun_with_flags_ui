defmodule FunWithFlags.UI.Router do
  use Plug.Router
  alias FunWithFlags.UI.{Templates, Utils}

  if Mix.env == :dev do
    use Plug.Debugger, otp_app: :fun_with_flags
  end

  plug Plug.Logger, log: :debug

  plug Plug.Static,
    gzip: true,
    at: Utils.prefix("/assets"),
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

    if Utils.valid_flag_name?(name) do
      case Utils.create_flag_with_name(name) do
        {:error, reason} -> html_resp(conn, 400, Templates.new(%{error_message: reason}))
        {:ok, _} -> redirect_to conn, "/flags/#{name}"
      end
    else
      html_resp(conn, 400, Templates.new(%{error_message: "Invalid flag name, it must match <code>/^\w+$/</code>."}))
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
    flag = get_flag(name)
    body = Templates.details(flag: flag)

    html_resp(conn, 200, body)
  end


  delete "/flags/:name" do
    Utils.clear_flag(name)
    redirect_to conn, "/flags"
  end

  patch "/flags/:name/boolean" do
    enabled = Utils.parse_bool(conn.params["enabled"])
    flag_name = String.to_atom(name)
    gate = FunWithFlags.Gate.new(:boolean, enabled)

    Utils.save_gate(flag_name, gate)
    redirect_to conn, "/flags/#{name}"
  end

  patch "/flags/:name/actors/:actor_id" do
    enabled = Utils.parse_bool(conn.params["enabled"])
    flag_name = String.to_atom(name)
    gate = %FunWithFlags.Gate{type: :actor, for: actor_id, enabled: enabled}

    Utils.save_gate(flag_name, gate)
    redirect_to conn, "/flags/#{name}#actor_#{actor_id}"
  end

  delete "/flags/:name/actors/:actor_id" do
    flag_name = String.to_atom(name)
    gate = %FunWithFlags.Gate{type: :actor, for: actor_id, enabled: false}

    Utils.clear_gate(flag_name, gate)
    redirect_to conn, "/flags/#{name}#actor_gates"
  end

  patch "/flags/:name/groups/:group_name" do
    enabled = Utils.parse_bool(conn.params["enabled"])
    flag_name = String.to_atom(name)
    group_name = String.to_atom(group_name)
    gate = %FunWithFlags.Gate{type: :group, for: group_name, enabled: enabled}

    Utils.save_gate(flag_name, gate)
    redirect_to conn, "/flags/#{name}#group_#{group_name}"
  end

  delete "/flags/:name/groups/:group_name" do
    flag_name = String.to_atom(name)
    group_name = String.to_atom(group_name)
    gate = %FunWithFlags.Gate{type: :group, for: group_name, enabled: false}

    Utils.clear_gate(flag_name, gate)
    redirect_to conn, "/flags/#{name}#group_gates"
  end


  post "/flags/:name/actors" do
    flag_name = String.to_atom(name)
    actor_id = conn.params["actor_id"]

    if Utils.blank?(actor_id) do
      flag = get_flag(name)
      body = Templates.details(flag: flag, actor_error_message: "The actor ID can't be blank.")
      html_resp(conn, 400, body)
    else
      enabled = Utils.parse_bool(conn.params["enabled"])
      gate = %FunWithFlags.Gate{type: :actor, for: actor_id, enabled: enabled}

      Utils.save_gate(flag_name, gate)
      redirect_to conn, "/flags/#{name}#actor_#{actor_id}"
    end
  end


  post "/flags/:name/groups" do
    flag_name = String.to_atom(name)
    group_name = conn.params["group_name"]

    if Utils.blank?(group_name) do
      flag = get_flag(name)
      body = Templates.details(flag: flag, group_error_message: "The group name can't be blank.")
      html_resp(conn, 400, body)
    else
      enabled = Utils.parse_bool(conn.params["enabled"])
      gate = FunWithFlags.Gate.new(:group, String.to_atom(group_name), enabled)

      Utils.save_gate(flag_name, gate)
      redirect_to conn, "/flags/#{name}#group_#{group_name}"
    end
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

  defp get_flag(name) do
    {:ok, flag} = FunWithFlags.SimpleStore.lookup(String.to_atom(name))
    flag
  end
end
