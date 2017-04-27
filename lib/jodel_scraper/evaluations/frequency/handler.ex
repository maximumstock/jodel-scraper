defmodule Evaluations.Frequency.Handler do

  require Logger

  alias JodelScraper.Repo
  alias JodelScraper.FrequencyJodel

  def handle(data, state) do
    data
    |> Enum.map(&(transform_jodel(&1, state)))
    |> Enum.map(&(Repo.insert(&1, [on_conflict: :nothing])))
  end

  defp transform_jodel(jodel, state) do

    {:ok, created_at, 0} = jodel["created_at"] |> DateTime.from_iso8601
    {:ok, updated_at, 0} = jodel["updated_at"] |> DateTime.from_iso8601

    %FrequencyJodel{
      post_id: jodel["post_id"],
      interval: state.interval,
      created_at: created_at,
      updated_at: updated_at,
      record_created_at: DateTime.utc_now()
    }
  end

end
