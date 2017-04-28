defmodule JodelScraper.Repo.Migrations.FrequencyTests do
  use Ecto.Migration

  def change do
    create table(:frequency_tests, primary_key: false) do
      add :interval, :integer, primary_key: true
      add :post_id, :string, size: 24, primary_key: true
      add :created_at, :timestamptz
      add :updated_at, :timestamptz
      add :record_created_at, :timestamptz
    end
  end
end
