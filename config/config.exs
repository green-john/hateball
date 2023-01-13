# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :hateball,
  ecto_repos: [Hateball.Repo]

# Configures the endpoint
config :hateball, HateballWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "AZPip+GJDz6Tlv0CXWEZAl2BRCBU+7P+RZVJunyqUbCWWLdYZn+dyV3r0nByrHOx",
  render_errors: [view: HateballWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Hateball.PubSub,
  live_view: [signing_salt: "d9Rz7ysF"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :esbuild,
  version: "0.14.41",
  default: [
  args: ~w(js/app.js --bundle --target=es2016 --outdir=../priv/static/assets),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :dart_sass,
  version: "1.54.5",
  default: [
    args: ~w(css/app.scss ../priv/static/assets/app.css),
    cd: Path.expand("../assets", __DIR__),
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
