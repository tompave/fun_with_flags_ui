# FunWithFlags.UI

[![Build Status](https://travis-ci.org/tompave/fun_with_flags_ui.svg?branch=master)](https://travis-ci.org/tompave/fun_with_flags_ui)
[![Hex.pm](https://img.shields.io/hexpm/v/fun_with_flags_ui.svg)](https://hex.pm/packages/fun_with_flags_ui)

A Web dashboard for the [FunWithFlags](https://github.com/tompave/fun_with_flags) Elixir package.

![](https://raw.githubusercontent.com/tompave/fun_with_flags_ui/master/demo/demo.gif)


## How to run

`FunWithFlags.UI` is just a plug and it can be run in a number of ways.
It's primarily meant to be embedded in a host Plug application, either Phoenix or another Plug app.

### Mounted in Phoenix

The router plug can be mounted inside the Phoenix router with [`Phoenix.Router.forward/4`](https://hexdocs.pm/phoenix/Phoenix.Router.html#forward/4).

```elixir
defmodule MyPhoenixApp.Web.Router do
  use MyPhoenixApp.Web, :router

  pipeline :mounted_apps do
    plug :accepts, ["html"]
    plug :put_secure_browser_headers
  end

  scope path: "/feature-flags" do
    pipe_through :mounted_apps
    forward "/", FunWithFlags.UI.Router, namespace: "feature-flags"
  end
end
```

### Mounted in another Plug application

Since it's just a plug, it can also be mounted into any other Plug application using [`Plug.Router.forward/2`](https://hexdocs.pm/plug/Plug.Router.html#forward/2).

```elixir
defmodule Another.App do
  use Plug.Router
  forward "/feature-flags", to: FunWithFlags.UI.Router, init_opts: [namespace: "feature-flags"]
end
```

### Standalone

Again, because it's just a plug, it can be run standalone in [different](https://hexdocs.pm/plug/readme.html#supervised-handlers) [ways](https://hexdocs.pm/plug/Plug.Adapters.Cowboy.html#http/3).

If you clone the repository, the library comes with two convenience functions to accomplish this:

```elixir
# Simple, let Cowboy sort out the supervision tree:
{:ok, pid} = FunWithFlags.UI.run_standalone()

# Uses some explicit supervision configuration:
{:ok, pid} = FunWithFlags.UI.run_supervised()
```

These functions come in handy for local development, and are _not_ necessary when embedding the Plug into a host application.

Please note that even though the `FunWithFlags.UI` module implements the `Application` behavior and comes with a proper `start/2` callback, this is not enabled by design and, in fact, the Mixfile doesn't declare an entry module.

If you really need to run it standalone in a reliable manner, you are encouraged to write your own supervision setup.

### Security

For obvious reasons, you don't want to make this web control panel publicly accessible.

The library itself doesn't provide any auth functionality because, as a Plug, it is easier to wrap it into the authentication and authorization logic of the host application.

The easiest thing to do is to protect it with HTTP Basic Auth, provided by the [`basic_auth`](https://hex.pm/packages/basic_auth) plug.

For example, in Phoenix:

```elixir
defmodule MyPhoenixApp.Web.Router do
  use MyPhoenixApp.Web, :router

  def my_basic_auth(conn, username, password) do
    if username == "foo" && password == "bar" do
      conn
    else
      Plug.Conn.halt(conn)
    end
  end

  pipeline :mounted_and_protected_apps do
    plug :accepts, ["html"]
    plug :put_secure_browser_headers
    plug BasicAuth, callback: &__MODULE__.my_basic_auth/3
  end

  scope path: "/feature-flags" do
    pipe_through :mounted_and_protected_apps
    forward "/", FunWithFlags.UI.Router, namespace: "feature-flags"
  end
end
```

## Caveats

While the base `fun_with_flags` library is quite relaxed in terms of valid flag names, group names and actor identifers, this web dashboard extension applies some more restrictive rules.
The reason is that all `fun_with_flags` cares about is that some flag and group names can be represented as an Elixir Atom, while actor IDs are just strings. Since you can use that API in your code, the library will only check that the parameters have the right type.

Things change on the web, however. Think about the binary `"Ook? Ook!"`. In code, it can be accepted as a valid flag name:

```elixir
{:ok, true} = FunWithFlags.enable(:"Ook? Ook!", for_group: :"weird, huh?")
```

On the web, however, the question mark makes working with URLs a bit tricky: in `http://localhost:8080/flags/Ook?%20Ook!`, the flag name will be `Ook` and the rest will be a query string.

For this reason this library enforces some stricter rules when creating flags and groups. Blank values are not allowed, `?` neither, and flag names must match `/^w+$/`.


## Installation

The package can be installed by adding `fun_with_flags_ui` to your list of dependencies in `mix.exs`.  
It requires [`fun_with_flags`](https://hex.pm/packages/fun_with_flags), see its [installation documentation](https://github.com/tompave/fun_with_flags#installation) for more details.

```elixir
def deps do
  [{:fun_with_flags_ui, "~> 0.2.0"}]
end
```
