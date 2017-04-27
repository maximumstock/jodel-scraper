defmodule JodelScraper.Repo.Migrations.SimpleOverlapTests do
  use Ecto.Migration

  def change do
    create table(:simple_overlap_tests) do
      add :scraper_id, :integer
      add :post_id, :string, size: 24
      add :created_at, :timestamptz
      add :updated_at, :timestamptz
      add :record_created_at, :timestamptz
    end
  end
end
