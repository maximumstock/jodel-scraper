defmodule JodelScraper.Evaluations.Frequency.Processor do
  use GenStage

  require Logger

  def start_link do
    GenStage.start_link(__MODULE__, :ok)
  end

  def init(_) do
    {:consumer, %{latest: [], from: 0}}
  end

  def ask(pid) do
    GenStage.cast(pid, :ask)
  end

  def handle_subscribe(:producer, _opts, from, state) do
    state = %{state | from: from}
    {:manual, state}
  end

  def handle_events(events, _from, state) do
    state = %{state | latest: events}
    Logger.info("Processing #{length(events)} jodels")
    {:noreply, [], state}
  end

  def handle_cast(:ask, state) do
    GenStage.ask(state.from, 200)
    {:noreply, [], state}
  end

end
