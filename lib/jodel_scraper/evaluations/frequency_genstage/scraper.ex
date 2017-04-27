defmodule JodelScraper.Evaluations.Frequency.Scraper do
  use GenStage

  alias JodelScraper.Client, as: API
  alias JodelScraper.TokenStore

  def start_link(state) do
    GenStage.start_link(__MODULE__, state)
  end

  def start_test() do
    __MODULE__.start_link(%{lat: 49.71, lng: 9.97, feed: "popular"})
  end

  def init(state) do
    {:producer, state}
  end

  def handle_demand(_, state) do
    {:ok, token} = TokenStore.token(%{lat: state.lat, lng: state.lng})
    jodels = API.get_jodel_feed(token, state.feed)
    {:noreply, jodels, state}
  end


end
