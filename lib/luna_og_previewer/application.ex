defmodule LunaOgPreviewer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      LunaOgPreviewerWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:luna_og_previewer, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: LunaOgPreviewer.PubSub},
      # Start a worker by calling: LunaOgPreviewer.Worker.start_link(arg)
      # {LunaOgPreviewer.Worker, arg},
      # Start to serve requests, typically the last entry
      LunaOgPreviewerWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: LunaOgPreviewer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LunaOgPreviewerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
