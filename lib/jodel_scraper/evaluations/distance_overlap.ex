defmodule JodelScraper.Evaluations.DistanceOverlap do

  alias JodelScraper.Client, as: API

  require Logger


  def test_wuerzburg_10km(feed, location_accuracy) do
    [
      %{name: "Rottendorf", lat: 49.7904, lng: 10.0269},
      %{name: "Heidingsfeld", lat: 49.7633, lng: 9.9481},
      %{name: "Neubrunn bei Würzburg", lat: 49.728711, lng: 9.670161},
      %{name: "Margetshöchheim", lat: 49.8354, lng: 9.8685}
    ]
    |> evaluate(feed, location_accuracy)
  end

  def test_berlin_10km(feed, location_accuracy) do
    [
      %{name: "Spandau", lat: 52.5361, lng: 13.1956},
      %{name: "Reinickendorf", lat: 52.5716, lng: 13.346},
      %{name: "Tempelhof", lat: 52.4632, lng: 13.3857},
      %{name: "Marzahn", lat: 52.5442, lng: 13.563},
      %{name: "Friedrichshain", lat: 52.512, lng: 13.4502}
    ]
    |> evaluate(feed, location_accuracy)
  end

  def test_berlin_18500m(feed, location_accuracy) do
    [
      %{name: "Charlottenburg-Willmersdorf", lat: 52.4824, lng: 13.2708},
      %{name: "Treptow-Köpenick", lat: 52.463, lng: 13.5453},
      %{name: "Lichtenberg", lat: 52.5741, lng: 13.5156}
    ]
    |> evaluate(feed, location_accuracy)
  end

  def evaluate(locations, feed, location_accuracy) do

    results = Enum.map(locations, fn loc ->
      loc
      |> location_to_token(location_accuracy)
      |> API.get_jodel_feed(feed)
      |> feed_to_ids
    end)

    range = 0..length(locations)-1
    Enum.each(range, fn x ->
      Enum.each(range, fn y ->
        if x != y do
          compare({Enum.at(locations, x), Enum.at(results, x)}, {Enum.at(locations, y), Enum.at(results, y)})
        end
      end)
    end)

  end

  defp compare({loc1, result1}, {loc2, result2}) do
    overlap = length(result1 -- (result1 -- result2))
    Logger.info("Overlap between #{loc1.name} (#{length(result1)}) and #{loc2.name} (#{length(result2)}): #{overlap}")
  end

  defp location_to_token(location, location_accuracy) do
    {:ok, %{status_code: 200, body: body}} = API.request_token(location.lat, location.lng, location_accuracy)
    body |> Poison.decode! |> Map.get("access_token")
  end

  defp feed_to_ids(posts) do
    posts |> Enum.map(fn post -> post["post_id"] end)
  end


end
