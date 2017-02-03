defmodule Jodels.Repo.Migrations.CreateJodels do
  use Ecto.Migration

  def change do
    create table(:jodels, primary_key: false) do
      add :post_id, :string, size: 24, primary_key: true
      add :message, :text
      add :pin_count, :integer, default: 0
      add :hex_color, :string, size: 6
      add :distance, :integer, default: 0
      add :child_count, :integer, default: 0
      add :vote_count, :integer, default: 0
      add :location_name, :text
      add :user_handle, :string, size: 45
      add :image_url, :text, default: nil
      add :parent, :string, [references(:jodels, on_delete: :delete_all), size: 24, default: nil]
      add :created_at, :timestamptz
      add :updated_at, :timestamptz
    end
  end
end
