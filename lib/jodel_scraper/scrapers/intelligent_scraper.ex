defmodule IntelligentScraper do
  use GenServer

  alias JodelClient, as: API
  alias TokenStore

  require Logger

  defstruct [
    :name,
    :lat,
    :lng,
    :feed,
    :interval,
    cache: [],
    latest: [],
    overlap_threshold: 10,
    interval_step: 10
  ]

  def start_link(state, options \\ []) do
    GenServer.start_link(__MODULE__, state, options)
  end

  def init(state) do
    start(state)
    {:ok, state}
  end

  def stop(pid) do
    GenServer.call(pid, :stop)
  end

  def start_test do
    test_state = %IntelligentScraper{name: "Würzburg", lat: 49.780888, lng: 9.967937, feed: :recent, interval: 3}
    GenServer.start_link(__MODULE__, test_state)
  end



  # Callbacks

  def handle_call(:stop, _from, state) do
    {:stop, :normal, state}
  end

  def handle_info(:work, state) do
    Logger.info("Scraping #{state.name} - #{state.feed}")

    key = %{lat: state.lat, lng: state.lng}

    case TokenStore.token(key) do
      {:ok, token}      -> scrape(token, state.feed)
      {:error, reason}  -> Logger.info("TokenStore could not acquire API token for #{state.name} (#{state.lat},#{state.lng}) (#{reason})")
    end

    schedule_scraping(state.interval)
    {:noreply, state}
  end

  def handle_call(:get_latest, state) do
    latest = Map.get(state, :latest, [])
    {:reply, latest, state}
  end

  def handle_call(:get_cache, state) do
    cache = Map.get(state, :cache, [])
    {:reply, cache, state}
  end

  def handle_cast({:update_interval, new_interval}, state) do
    Logger.info("Interval change #{state.interval}s -> #{new_interval}s (#{state.name} - #{state.feed})")
    new_state = Map.put(state, :interval, new_interval)
    {:noreply, new_state}
  end

  def handle_cast({:adapt_interval, latest_jodels}, state) do

    new = latest_jodels |> Enum.map(fn x -> x["post_id"] end)
    old = state.latest
    overlap = length(new -- (new -- old))
    threshold = state.overlap_threshold
    step = state.interval_step
    base = state.interval

    new_interval =
      case overlap do
        a when a > threshold      -> base + step
        a when (base - step) < 0  -> base
        0                         -> base - step
        _                         -> base
      end

    if new_interval != state.interval do
      Logger.info("Interval change #{state.interval} -> #{new_interval} (#{state.name} - #{state.feed})")
    end

    new_state = %{ state | interval: new_interval, latest: new }
    {:noreply, new_state}

  end


  # API

  def update_interval(new_interval) do
    GenServer.cast(self(), {:update_interval, new_interval})
  end

  def get_latest(pid) do
    GenServer.call(pid, :get_latest)
  end

  def get_cache(pid) do
    GenServer.call(pid, :get_cache)
  end

  defp start(state) do
    Logger.info("Init scraper - #{state.name} - #{state.feed} (every #{state.interval}s)")
    schedule_scraping(0)
  end


  defp scrape(token, feed) when is_atom(feed) do
    case feed do
      :popular    -> scrape(token, "popular")
      :discussed  -> scrape(token, "discussed")
      _           -> scrape(token, "")
    end
  end

  # Helpers

  defp scrape(token, feed) when is_bitstring(feed) do
    API.get_jodel_feed(token, feed)
    |> process
  end

  defp process(jodels) do
    GenServer.cast(self(), {:adapt_interval, jodels})
  end

  defp schedule_scraping(delay) do
    Process.send_after(self(), :work, delay * 1000)
  end

end
