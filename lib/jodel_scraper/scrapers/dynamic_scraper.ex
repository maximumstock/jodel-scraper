defmodule Scrapers.DynamicScraper do

  @moduledoc """

  """

  use GenServer

  alias JodelScraper.Client, as: API
  alias JodelScraper.TokenStore, as: TokenStore

  require Logger

  defstruct [
    :name,
    :lat,
    :lng,
    :feed,
    :interval,
    id: :rand.uniform(1000),
    handlers: [],
    latest: [],
    overlap_threshold: 10,
    interval_step: 10
  ]

  def start_link(%__MODULE__{} = state, options \\ []) do
    GenServer.start_link(__MODULE__, state, options)
  end

  def init(%__MODULE__{} = state) do
    schedule_scraping(self(), 0)
    {:ok, state}
  end

  def stop(pid) do
    GenServer.call(pid, :stop)
  end

  @doc """
  A helper method to start up an instance of this scraper implementation for Würzburg
  """
  def start_test do
    test_state = %__MODULE__{name: "Würzburg", lat: 49.780888, lng: 9.967937, feed: :recent, interval: 3}
    GenServer.start_link(__MODULE__, test_state)
  end


  # API

  @doc """
  Client-API to update the interval a scraper waits between scraping rounds
  """
  def update_interval(pid, new_interval) do
    GenServer.cast(pid, {:update_interval, new_interval})
  end

  @doc """
  Client-API to invoke scraping after @delay seconds
  """
  def schedule_scraping(pid, delay) do
    Process.send_after(pid, :work, delay * 1000)
  end


  defp scrape(token, feed) when is_atom(feed), do: scrape(token, map_feed_atom(feed))
  defp scrape(token, feed) when is_bitstring(feed) do
    API.get_jodel_feed(token, feed)
    |> process
  end

  defp map_feed_atom(:popular), do: "popular"
  defp map_feed_atom(:discussed), do: "discussed"
  defp map_feed_atom(_), do: ""

  defp process(data) do
    GenServer.cast(self(), {:process, data})
  end

  defp calculate_new_interval(new_data, old_data, overlap_threshold, current_interval, interval_step) do
    new_ids = new_data |> Enum.map(fn x -> x["post_id"] end)
    old_ids = old_data |> Enum.map(fn x -> x["post_id"] end)
    overlap = length(new_ids -- (new_ids -- old_ids))

    case overlap do
      a when a > overlap_threshold                    -> current_interval + interval_step
      _ when (current_interval - interval_step) < 0   -> current_interval
      0                                               -> current_interval - interval_step
      _                                               -> current_interval
    end
  end


  # Callbacks

  def handle_call(:stop, _from, state) do
    {:stop, :normal, state}
  end

  def handle_cast({:update_interval, new_interval}, state) do
    Logger.info("Interval change #{state.interval}s -> #{new_interval}s (#{state.name} - #{state.feed})")
    new_state = Map.put(state, :interval, new_interval)
    {:noreply, new_state}
  end


  def handle_cast({:process, data}, state) do

    new_interval = calculate_new_interval(data, state.latest, state.overlap_threshold, state.interval, state.interval_step)

    if new_interval != state.interval do
      update_interval(self(), new_interval)
    end

    Enum.each(state.handlers, fn {module, function} ->
      :erlang.apply(module, function, [data, state])
    end)

    schedule_scraping(self(), new_interval)
    new_state = %{state | latest: data}
    {:noreply, new_state}

  end

  def handle_info(:work, state) do
    Logger.info("Scraping #{state.name}")

    key = %{lat: state.lat, lng: state.lng}

    case TokenStore.token(key) do
      {:ok, token}      -> scrape(token, state.feed)
      {:error, reason}  -> Logger.info("TokenStore could not acquire API token for #{state.name} (#{state.lat},#{state.lng}) (#{reason})")
    end

    {:noreply, state}
  end


end
