defmodule JodelScraper.FrequencyJodel do
  use Ecto.Schema

  @primary_key {:id, :integer, []}

  schema "frequency_tests" do
    field :post_id, :string
    field :interval, :integer
    field :created_at, :utc_datetime
    field :updated_at, :utc_datetime
    field :record_created_at, :utc_datetime
  end
end
