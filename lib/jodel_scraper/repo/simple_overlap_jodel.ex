defmodule JodelScraper.SimpleOverlapJodel do
  use Ecto.Schema

  @primary_key {:id, :integer, []}

  schema "simple_overlap_tests" do
    field :post_id, :string
    field :scraper_id, :integer
    field :created_at, :utc_datetime
    field :updated_at, :utc_datetime
    field :record_created_at, :utc_datetime
  end
end
