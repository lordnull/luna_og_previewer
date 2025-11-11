defmodule LunaOgPreviewer.Repo do
  use Ecto.Repo,
    otp_app: :luna_og_previewer,
    adapter: Ecto.Adapters.Postgres
end
