defmodule Evaluations.Overlap.Simple.Supervisor do
  use Supervisor

  alias Scrapers.DynamicScraper

  #@intervals [20, 25, 30, 35, 40, 45, 50, 60]
  @intervals [5, 10, 15, 20]

  def start do
    __MODULE__.start_link()
  end

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  def init([]) do

    params =
      for interval <- @intervals, id <- [1,2] do
        %{interval: interval, id: id}
      end

    children =
      params
      |> Enum.map(fn p ->
        %DynamicScraper{
          name: "Berlin | recent | #{p.interval}s",
          id: p.id,
          lat: 52.5216702,
          lng: 13.4026643,
          feed: :recent,
          interval: p.interval,
          interval_step: 0,
          handlers: [{Evaluations.Overlap.Simple.Handler, :handle}]
        }
      end)
      |> Enum.map(fn state ->
        worker(DynamicScraper, [state], [id: make_ref()])
      end)

    supervise(children, [strategy: :one_for_one])

  end

end
