defmodule JodelScraper.Repo.Migrations.PartialOverlapTests do
  use Ecto.Migration

  def change do
    create table(:partial_overlap_tests) do
      add :scraper_id, :integer
      add :post_id, :string, size: 24
      add :created_at, :timestamptz
      add :updated_at, :timestamptz
      add :record_created_at, :timestamptz
    end
  end
end
