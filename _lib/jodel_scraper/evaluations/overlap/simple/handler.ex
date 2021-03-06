defmodule Evaluations.Overlap.Simple.Handler do

  require Logger

  alias JodelScraper.Repo
  alias JodelScraper.SimpleOverlapJodel

  def handle(data, state) do
    list = Enum.map(data, &(transform_jodel(&1, state)))
    Repo.insert_all(SimpleOverlapJodel, list ,[on_conflict: :nothing])
  end

  defp transform_jodel(jodel, state) do

    {:ok, created_at, 0} = jodel["created_at"] |> DateTime.from_iso8601
    {:ok, updated_at, 0} = jodel["updated_at"] |> DateTime.from_iso8601

    %{
      post_id: jodel["post_id"],
      interval: state.interval,
      scraper_id: state.id,
      created_at: created_at,
      updated_at: updated_at,
      record_created_at: DateTime.utc_now()
    }
  end

end
