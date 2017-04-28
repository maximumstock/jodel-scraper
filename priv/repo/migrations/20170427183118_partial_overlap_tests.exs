defmodule JodelScraper.Repo.Migrations.PartialOverlapTests do
  use Ecto.Migration

  def change do
    create table(:partial_overlap_tests, primary_key: false) do
      add :scraper_id, :integer, primary_key: true
      add :post_id, :string, size: 24, primary_key: true
      add :created_at, :timestamptz
      add :updated_at, :timestamptz
      add :record_created_at, :timestamptz
    end
  end
end
