defmodule HateballWeb.Presence do
  use Phoenix.Presence,
      otp_app: :hateball,
      pubsub_server: Hateball.PubSub
end