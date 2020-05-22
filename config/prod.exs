use Mix.Config

config :hateball, HateballWeb.Endpoint,
  url: [host: "ruizandr.es", path: "/hateball", port: 80],
  cache_static_manifest: "priv/static/cache_manifest.json"

config :logger, level: :info

import_config "prod.secret.exs"
