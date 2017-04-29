defmodule Evaluations.Overlap.Simple.Supervisor do
  use Supervisor

  alias Scrapers.DynamicScraper

  def start do
    __MODULE__.start_link()
  end

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  def init([]) do

    children =
      Range.new(1, 2)
      |> Enum.map(fn id ->
        %DynamicScraper{
          name: "Berlin | recent | #{100}s",
          id: id,
          lat: 52.5216702,
          lng: 13.4026643,
          feed: :recent,
          interval: 100,
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
