defmodule JodelScraper.Repo.Migrations.FrequencyTests do
  use Ecto.Migration

  def change do
    create table(:frequency_tests) do
      add :interval, :integer
      add :post_id, :string, size: 24
      add :created_at, :timestamptz
      add :updated_at, :timestamptz
      add :record_created_at, :timestamptz
    end
  end
end
