defmodule Evaluations.Overlap.Partial.Supervisor do
  use Supervisor

  alias Scrapers.DynamicScraper

  def start do
    __MODULE__.start_link()
  end

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  def init([]) do

		# locations = [%{
    #   name: "Berlin Base",
    #   lat: 52.522254,
    #   lng: 13.226990,
    #   id: 1
    # }, %{
    #   name: "Berlin 2",
    #   lat: 52.525596,
    #   lng: 13.327240,
    #   id: 2
    # }, %{
    #   name: "Berlin 3",
    #   lat: 52.528938,
    #   lng: 13.443970,
    #   id: 3
    # }, %{
    #   name: "Berlin 4",
    #   lat: 52.531445,
    #   lng: 13.606018,
    #   id: 4
    # }]

    locations = [%{
        name: "München 1",
        lat: 48.1485,
        lng: 11.4629,
        id: 1
      }, %{
        name: "München 2",
        lat: 48.1485,
        lng: 11.4973,
        id: 2
      }, %{
        name: "München 3",
        lat: 48.1485,
        lng: 11.5296,
        id: 3
      }, %{
        name: "München 4",
        lat: 48.1485,
        lng: 11.5620,
        id: 4
      }, %{
        name: "München 5",
        lat: 48.1485,
        lng: 11.6020,
        id: 5
      }]

		children =
      locations
      |> Enum.map(fn location ->
        %DynamicScraper{
          name: location.name,
          lat: location.lat,
          lng: location.lng,
          id: location.id,
          feed: :recent,
          interval: 30,
          interval_step: 0,
          handlers: [{Evaluations.Overlap.Partial.Handler, :handle}]
        }
      end)
      |> Enum.map(fn state ->
        worker(DynamicScraper, [state], [id: make_ref()])
      end)

    supervise(children, [strategy: :one_for_one])

  end

end
