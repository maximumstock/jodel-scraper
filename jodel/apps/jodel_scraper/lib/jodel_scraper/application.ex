defmodule JodelScraper.Application do
  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias Locations
  alias JodelClient
  alias Scrapers
  alias TokenStore

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    scraper_children =
      Locations.default_locations()
      |> Enum.take(0)
      |> Enum.map(fn loc ->
        worker(Scrapers.DynamicScraper, [%Scrapers.DynamicScraper{
          name: "#{loc.name}/recent",
          lat: loc.lat,
          lng: loc.lng,
          feed: :recent,
          interval: 60}], [id: make_ref()])
      end)

    # Define workers and child supervisors to be supervised
    children = [
      # Starts a worker by calling: JodelScraper.Worker.start_link(arg1, arg2, arg3)
      # worker(JodelScraper.Worker, [arg1, arg2, arg3]),
      worker(TokenStore, [])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: JodelScraper.Supervisor]
    Supervisor.start_link(children ++ scraper_children, opts)
  end
end
