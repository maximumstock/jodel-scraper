defmodule JodelScraper.FrequencyJodel do
  use Ecto.Schema

  @primary_key false

  schema "frequency_tests" do
    field :post_id, :string, primary_key: true
    field :interval, :integer, primary_key: true
    field :created_at, :utc_datetime
    field :updated_at, :utc_datetime
    field :record_created_at, :utc_datetime
  end
end
