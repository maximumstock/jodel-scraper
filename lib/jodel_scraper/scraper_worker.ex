defmodule JodelScraper.ScraperWorker do
  use GenServer
  alias JodelScraper.JodelApiClient

  #defstruct do
  #  location: %{
  #    country_code: "DE",
  #    city_name: "Würzburg",
  #    lat: 49.713862,
  #    lng: 9.973702
  #  },
  #  sort: "popular",
  #  interval: 90
  #end

  def start_link(state, options \\ []) do
    GenServer.start_link(__MODULE__, state, options)
  end

  def init(state) do
    {:ok, state}
  end

  # def scrape(state) do
  #   api_token = JodelApiClient.get_api_token(state.location.country, state.location.city, state.location.lat, state.location.lng)
  #     |> extract_token
  #
  #   load_jodels(api_token, "", state.sort)
  #     |> parse_jodels
  #     |> store_jodels
  # end
  #
  # defp extract_token(response) do
  #   {:ok, %{"access_token" => access_token}} = Poison.decode(response_body)
  #   access_token
  # end
  #
  # defp load_jodels(token, after_jodel_id \\ "", sort \\ "popular") do
  #    {:ok, %{body: body}} = get_jodels(access_token, after_jodel_id, sort)
  #    body
  # end
  #
  # defp parse_jodels(response_body) do
  #    {:ok, posts} = Poison.decode(response_body)
  #    IO.inspect posts
  # end



end
