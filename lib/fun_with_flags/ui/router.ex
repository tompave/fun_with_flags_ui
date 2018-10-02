defmodule FunWithFlags.UI.Router do
  @moduledoc """
  A `Plug.Router`. This module is meant to be plugged into host applications.

  See the [Readme](/fun_with_flags_ui/readme.html#how-to-run) for more detailed instructions.
  """

  use Plug.Router
  alias FunWithFlags.UI.{Templates, Utils}
  alias FunWithFlags.UI.SimpleActor

  if Mix.env == :dev do
    use Plug.Debugger, otp_app: :fun_with_flags_ui
  end

  plug Plug.Logger, log: :debug

  plug Plug.Static,
    gzip: true,
    at: "/assets",
    from: :fun_with_flags_ui

  plug :fetch_session
  plug Plug.CSRFProtection

  plug Plug.Parsers, parsers: [:urlencoded]
  plug Plug.MethodOverride

  plug :assign_csrf_token
  plug :match
  plug :dispatch

  @doc false
  def call(conn, opts) do
    conn = extract_namespace(conn, opts)
    super(conn, opts)
  end


  get "/" do
    conn
    |> redirect_to("/flags")
  end


  # form to create a new flag
  #
  get "/new" do
    conn
    |> html_resp(200, Templates.new(%{conn: conn}))
  end


  # endpoint to create a new flag
  #
  post "/flags" do
    name = Utils.sanitize(conn.params["flag_name"])

    case Utils.validate_flag_name(conn, name) do
      :ok ->
        case Utils.create_flag_with_name(name) do
          {:ok, _} -> redirect_to conn, "/flags/#{name}"
          _ -> html_resp(conn, 400, Templates.new(%{conn: conn, error_message: "Something went wrong!"}))
        end
      {:fail, reason} ->
        html_resp(conn, 400, Templates.new(%{conn: conn, error_message: reason}))
    end
  end


  # get a list of the flags
  #
  get "/flags" do
    {:ok, flags} = FunWithFlags.all_flags
    flags = Utils.sort_flags(flags)
    body = Templates.index(conn: conn, flags: flags)

    conn
    |> html_resp(200, body)
  end


  # flag details
  #
  get "/flags/:name" do
    case Utils.get_flag(name) do
      {:ok, flag} ->
        body = Templates.details(conn: conn, flag: flag)
        html_resp(conn, 200, body)
      {:error, _} ->
        body = Templates.not_found(conn: conn, name: name)
        html_resp(conn, 404, body)
    end
  end


  # to clear an entire flag
  #
  delete "/flags/:name" do
    name
    |> String.to_existing_atom()
    |> FunWithFlags.clear()

    redirect_to conn, "/flags"
  end


  # to toggle the default state of a flag
  #
  patch "/flags/:name/boolean" do
    enabled = Utils.parse_bool(conn.params["enabled"])
    flag_name = String.to_existing_atom(name)

    if enabled do
      FunWithFlags.enable(flag_name)
    else
      FunWithFlags.disable(flag_name)
    end

    redirect_to conn, "/flags/#{name}"
  end


  # to clear a boolean gate
  #
  delete "/flags/:name/boolean" do
    flag_name = String.to_existing_atom(name)
    FunWithFlags.clear(flag_name, boolean: true)
    redirect_to conn, "/flags/#{name}"
  end


  # to toggle an actor gate
  #
  patch "/flags/:name/actors/:actor_id" do
    enabled = Utils.parse_bool(conn.params["enabled"])
    flag_name = String.to_existing_atom(name)
    actor = %SimpleActor{id: actor_id}

    if enabled do
      FunWithFlags.enable(flag_name, for_actor: actor)
    else
      FunWithFlags.disable(flag_name, for_actor: actor)
    end

    redirect_to conn, "/flags/#{name}#actor_#{actor_id}"
  end


  # to clear an actor gate
  #
  delete "/flags/:name/actors/:actor_id" do
    flag_name = String.to_existing_atom(name)
    actor = %SimpleActor{id: actor_id}

    FunWithFlags.clear(flag_name, for_actor: actor)
    redirect_to conn, "/flags/#{name}#actor_gates"
  end


  # to toggle a group gate
  #
  patch "/flags/:name/groups/:group_name" do
    enabled = Utils.parse_bool(conn.params["enabled"])
    flag_name = String.to_existing_atom(name)
    group_name = to_string(group_name)

    if enabled do
      FunWithFlags.enable(flag_name, for_group: group_name)
    else
      FunWithFlags.disable(flag_name, for_group: group_name)
    end

    redirect_to conn, "/flags/#{name}#group_#{group_name}"
  end


  # to clear a group gate
  #
  delete "/flags/:name/groups/:group_name" do
    flag_name = String.to_existing_atom(name)
    group_name = to_string(group_name)

    FunWithFlags.clear(flag_name, for_group: group_name)

    redirect_to conn, "/flags/#{name}#group_gates"
  end


  # to clear a percentage gate
  #
  delete "/flags/:name/percentage" do
    flag_name = String.to_existing_atom(name)
    FunWithFlags.clear(flag_name, for_percentage: true)
    redirect_to conn, "/flags/#{name}"
  end


  # to add a new actor to a flag
  #
  post "/flags/:name/actors" do
    flag_name = String.to_existing_atom(name)
    actor_id = Utils.sanitize(conn.params["actor_id"])

    case Utils.validate(actor_id) do
      :ok ->
        enabled = Utils.parse_bool(conn.params["enabled"])
        actor = %SimpleActor{id: actor_id}
        if enabled do
          FunWithFlags.enable(flag_name, for_actor: actor)
        else
          FunWithFlags.disable(flag_name, for_actor: actor)
        end
        redirect_to conn, "/flags/#{name}#actor_#{actor_id}"
      {:fail, reason} ->
        {:ok, flag} = Utils.get_flag(name)
        body = Templates.details(conn: conn, flag: flag, actor_error_message: "The actor ID #{reason}.")
        html_resp(conn, 400, body)
    end
  end


  # to add a new group to a flag
  #
  post "/flags/:name/groups" do
    flag_name = String.to_existing_atom(name)
    group_name = Utils.sanitize(conn.params["group_name"])

    case Utils.validate(group_name) do
      :ok ->
        enabled = Utils.parse_bool(conn.params["enabled"])
        if enabled do
          FunWithFlags.enable(flag_name, for_group: group_name)
        else
          FunWithFlags.disable(flag_name, for_group: group_name)
        end
        redirect_to conn, "/flags/#{name}#group_#{group_name}"
      {:fail, reason} ->
        {:ok, flag} = Utils.get_flag(name)
        body = Templates.details(conn: conn, flag: flag, group_error_message: "The group name #{reason}.")
        html_resp(conn, 400, body)
    end
  end


  # to add or replace a percentage gate
  #
  post "/flags/:name/percentage" do
    flag_name = String.to_existing_atom(name)
    type = Utils.parse_percentage_type(conn.params["percent_type"])

    case Utils.parse_and_validate_float(conn.params["percent_value"]) do
      {:ok, float} ->
        FunWithFlags.enable(flag_name, for_percentage_of: {type, float})
        redirect_to conn, "/flags/#{name}#percentage_gate"
      {:fail, reason} ->
        {:ok, flag} = Utils.get_flag(name)
        body = Templates.details(conn: conn, flag: flag, percentage_error_message: "The percentage value #{reason}.")
        html_resp(conn, 400, body)
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
    path = Path.join(conn.assigns[:namespace], uri)

    conn
    |> put_resp_header("location", path)
    |> put_resp_content_type("text/html")
    |> send_resp(302, "<html><body>You are being <a href=\"#{path}\">redirected</a>.</body></html>")
  end


  defp extract_namespace(conn, opts) do
    ns = opts[:namespace] || ""
    Plug.Conn.assign(conn, :namespace, "/" <> ns)
  end


  defp assign_csrf_token(conn, _opts) do
    csrf_token = Plug.CSRFProtection.get_csrf_token()
    Plug.Conn.assign(conn, :csrf_token, csrf_token)
  end
end
