defmodule Hateball.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false


  use Application

  def start(_type, _args) do
    children = [
      HateballWeb.Telemetry,
      {Phoenix.PubSub, name: Hateball.PubSub},
      {
        DynamicSupervisor,
        name: Hateball.DynamicSupervisor,
        strategy: :one_for_one
      },
      {Hateball.GameCatalog, %{}},
      HateballWeb.Presence,
      HateballWeb.Endpoint,
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Hateball.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    HateballWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
