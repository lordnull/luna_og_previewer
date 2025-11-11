defmodule LunaOgPreviewer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      LunaOgPreviewer.Repo,
      {DNSCluster, query: Application.get_env(:luna_og_previewer, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: LunaOgPreviewer.PubSub}
      # Start a worker by calling: LunaOgPreviewer.Worker.start_link(arg)
      # {LunaOgPreviewer.Worker, arg}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: LunaOgPreviewer.Supervisor)
  end
end
