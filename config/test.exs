use Mix.Config

config :logger, level: :error

config :fun_with_flags_ui, :flag_page,
  alias_fn: {FunWithFlags.UI.FlagTransform, :flag_with_aliases}
