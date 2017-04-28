# FunWithFlags.UI

A Web dashboard for the [FunWithFlags](https://github.com/tompave/fun_with_flags) Elixir package.

This package is still a work in progress.

## How to mount in Phoenix

```elixir
pipeline :mounted_apps do
  plug :accepts, ["html"]
  plug :put_secure_browser_headers
end

scope path: "/feature-flags" do
  pipe_through :mounted_apps
  forward "/", FunWithFlags.UI.Router, namespace: "feature-flags"
end
```

## Installation

The package can be installed by adding `fun_with_flags_ui` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:fun_with_flags_ui, "~> 0.0.1"}]
end
```
