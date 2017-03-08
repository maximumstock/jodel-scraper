defmodule JodelScraper.Application do
  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # Define workers and child supervisors to be supervised
    children = [
      # Starts a worker by calling: JodelScraper.Worker.start_link(arg1, arg2, arg3)
      # worker(JodelScraper.Worker, [arg1, arg2, arg3]),
      supervisor(JodelScraper.Repo, []),
      worker(TokenStore, [])
    ]

    locations = [
      %{city: "Würzburg", lat: 49.780888, lng: 9.967937},
      %{city: "Berlin", lat: 52.5216702, lng: 13.4026643},
      %{city: "München", lat: 48.1354216, lng: 11.5791273},
      %{city: "Köln", lat: 50.950, lng: 6.950},
      %{city: "Hamburg", lat: 53.567, lng: 10.033},
      %{city: "Stuttgart", lat: 48.783, lng: 9.183},
      %{city: "Leipzig", lat: 51.339, lng: 12.377},
      %{city: "Dresden", lat: 51.050, lng: 13.739},
      %{city: "Nürnberg", lat: 49.450, lng: 11.083},
      %{city: "Heidelberg", lat: 49.400, lng: 8.683},
      %{city: "Frankfurt am Main", lat: 50.122, lng: 8.680},
      %{city: "Düsseldorf", lat: 51.222, lng: 6.809},
      %{city: "Dortmund", lat: 51.507, lng: 7.474},
      %{city: "Essen", lat: 51.451, lng: 6.997},
      %{city: "Bremen", lat: 53.093, lng: 8.789},
      %{city: "Hannover", lat: 52.385, lng: 9.728},
      %{city: "Nürnberg", lat: 49.440, lng: 11.070},
      %{city: "Duisburg", lat: 51.444, lng: 6.752},
      %{city: "Bochum", lat: 51.476, lng: 7.219},
      %{city: "Bielefeld", lat: 52.014, lng: 8.534},
      %{city: "Münster", lat: 51.950, lng: 7.622}
    ]

    base_scraping_interval = Application.get_env(:jodel_scraper, JodelScraper)[:base_scraping_interval]

    if Mix.env == :prod do

      popular_children = Enum.map(locations, fn loc -> worker(ScraperWorker, [%{
          location: loc,
          type: :popular,
          interval: 5*base_scraping_interval
        }], [id: make_ref()]) end)

      recent_children = Enum.map(locations, fn loc -> worker(ScraperWorker, [%{
          location: loc,
          type: :recent,
          interval: base_scraping_interval
        }], [id: make_ref()]) end)

      discussed_children = Enum.map(locations, fn loc -> worker(ScraperWorker, [%{
          location: loc,
          type: :discussed,
          interval: 5*base_scraping_interval
        }], [id: make_ref()]) end)

      children = children ++ popular_children ++ recent_children ++ discussed_children
    end

    if Mix.env == :dev do
      children = children ++ [worker(ScraperWorker, [%{location: %{city: "München", lat: 48.1354216, lng: 11.5791273}, type: :popular, interval: base_scraping_interval}])]
    end

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: JodelScraper.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
