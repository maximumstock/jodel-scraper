defmodule JodelScraper.Jodel do
  use Ecto.Schema

  @primary_key {:post_id, :string, []}

  schema "jodels" do
    field :message, :string
    field :pin_count, :integer
    field :hex_color, :string
    field :distance, :integer
    field :child_count, :integer
    field :vote_count, :integer
    field :location_name, :string
    field :user_handle, :string
    field :image_url, :string
    field :parent, :string
    field :created_at, :utc_datetime
    field :updated_at, :utc_datetime
  end
end
