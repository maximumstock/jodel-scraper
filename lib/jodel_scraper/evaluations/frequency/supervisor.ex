defmodule Evaluations.Frequency.Supervisor do
  use Supervisor

  alias Scrapers.DynamicScraper

  @intervals [60, 120, 300, 600, 1200, 1800, 2400, 3600]

  def start do
    __MODULE__.start_link()
  end

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  def init([]) do

    children =
      @intervals
      |> Enum.map(fn interval ->
        %DynamicScraper{
          name: "Berlin | recent | #{interval}s",
          lat: 52.5216702,
          lng: 13.4026643,
          feed: :recent,
          interval: interval,
          interval_step: 0,
          handlers: [{Evaluations.Frequency.Handler, :handle}]
        }
      end)
      |> Enum.map(fn state ->
        worker(DynamicScraper, [state], [id: make_ref()])
      end)

    supervise(children, [strategy: :one_for_one])

  end

end
