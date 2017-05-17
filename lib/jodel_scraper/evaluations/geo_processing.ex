defmodule GeoProcessing do

  alias JodelScraper.Client, as: API
  alias JodelScraper.TokenStore

  def generate_grid(startLat, endLat, startLng, endLng, columns, rows) do
    stepX = (endLng - startLng) / columns
    stepY = (endLat - startLat) / rows

    List.flatten(Enum.map(0..rows-1, fn row -> generate_row(startLat, stepY, startLng, stepX, columns, row) end))
  end

  def generate_row(startLat, stepY, startLng, stepX, columns, row) do
    Enum.map(0..columns-1, fn column ->
      new_lat = Decimal.new(startLat + row*stepY) |> Decimal.round(6) |> Decimal.to_string
      new_lng = Decimal.new(startLng + column*stepX) |> Decimal.round(6) |> Decimal.to_string
      %{lat: new_lat, lng: new_lng}
    end)
  end

  def jodel_to_location(jodel, location) do
    %{
      lat: location.lat,
      lng: location.lng,
      name: jodel["location"]["name"]
    }
  end

  def start do

    {:ok, file} = File.open("geo_processing_result.json", [:write])

    result =
      generate_grid(49.3203, 50.0707, 11.1042, 9.7938, 7, 7)
      |> IO.inspect
      |> Enum.map(fn location ->
        {:ok, token} = TokenStore.token(%{name: "", lat: location.lat, lng: location.lng})
        API.get_jodel_feed(token, "") |> Enum.map(&(jodel_to_location(&1, location)))
      end)
      |> List.flatten
      |> Enum.uniq
      |> Enum.group_by(fn x -> "#{x.lat}-#{x.lng}" end)
      |> Poison.encode!

    IO.binwrite(file, result)
    File.close(file)

  end

end
