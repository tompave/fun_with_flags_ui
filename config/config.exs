use Mix.Config

# Do not bother trying to emit cache-busting notifications,
# so that we don't need to declare the optional dependencies.
#
# This only applies to the dev env of the library, and this
# config file won't even be included in the packaged library.
#
config :fun_with_flags, :cache_bust_notifications, enabled: false

case Mix.env do
  :test -> import_config "test.exs"
  _     -> nil
end
