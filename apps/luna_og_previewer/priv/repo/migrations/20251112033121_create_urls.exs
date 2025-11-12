defmodule LunaOgPreviewer.Repo.Migrations.CreateUrls do
  use Ecto.Migration

  def change do
    create table(:urls) do
      add :normalized_url, :string, primary_key: true
      add :use_https, :boolean
      add :preview_url, :string
      add :in_progress, :boolean
      add :last_updated, :utc_datetime
    end
  end
end
