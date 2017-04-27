defmodule JodelScraper.Application do
  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias JodelScraper.TokenStore

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
      %{name: "Würzburg", lat: 49.780888, lng: 9.967937},
      %{name: "Berlin", lat: 52.5216702, lng: 13.4026643},
      %{name: "München", lat: 48.1354216, lng: 11.5791273},
      %{name: "Köln", lat: 50.950, lng: 6.950},
      %{name: "Hamburg", lat: 53.567, lng: 10.033},
      %{name: "Stuttgart", lat: 48.783, lng: 9.183},
      %{name: "Leipzig", lat: 51.339, lng: 12.377},
      %{name: "Dresden", lat: 51.050, lng: 13.739},
      %{name: "Nürnberg", lat: 49.450, lng: 11.083},
      %{name: "Heidelberg", lat: 49.400, lng: 8.683},
      %{name: "Frankfurt am Main", lat: 50.122, lng: 8.680},
      %{name: "Düsseldorf", lat: 51.222, lng: 6.809},
      %{name: "Dortmund", lat: 51.507, lng: 7.474},
      %{name: "Essen", lat: 51.451, lng: 6.997},
      %{name: "Bremen", lat: 53.093, lng: 8.789},
      %{name: "Hannover", lat: 52.385, lng: 9.728},
      %{name: "Nürnberg", lat: 49.440, lng: 11.070},
      %{name: "Duisburg", lat: 51.444, lng: 6.752},
      %{name: "Bochum", lat: 51.476, lng: 7.219},
      %{name: "Bielefeld", lat: 52.014, lng: 8.534},
      %{name: "Münster", lat: 51.950, lng: 7.622}
    ]

    base_scraping_interval = Application.get_env(:jodel_scraper, JodelScraper)[:base_scraping_interval]

    popular_children = []

    children = children ++
      case Mix.env do
        :prod -> popular_children
        :dev -> [] #[worker(ScraperWorker, [%{name: "München", lat: 48.1354216, lng: 11.5791273, feed: :popular, interval: base_scraping_interval}])]
      end

    # if Mix.env == :dev do
    #   children = children ++ [worker(ScraperWorker, [%{name: "München", lat: 48.1354216, lng: 11.5791273, type: :popular, interval: base_scraping_interval}])]
    # end

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: JodelScraper.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
