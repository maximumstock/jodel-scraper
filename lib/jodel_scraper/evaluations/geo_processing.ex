defmodule GeoProcessing do

  alias JodelClient, as: API
  alias TokenStore

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

  def get_locations_for_grid(lat_start, lat_end, lng_start, lng_end, lat_num, lng_num) do
    generate_grid(lat_start, lat_end, lng_start, lng_end, lat_num, lng_num)
    |> Enum.map(fn location ->
      {:ok, token} = TokenStore.token(%{lat: location.lat, lng: location.lng})
      {:ok, feed} = API.get_feed(token, :recent)
      feed |> Enum.map(&(jodel_to_location(&1, location)))
    end)
    |> List.flatten
    |> Enum.uniq
    # |> Enum.group_by(fn x -> "#{x.lat}-#{x.lng}" end)
  end

  def get_geo_for_location_name(name) do
    key = "AIzaSyBQ8R7dzz_UVZ5yFRUvKeEJA0eFFGuB9hw"
    url = "https://maps.googleapis.com/maps/api/geocode/json?address=#{URI.encode(name)}&key=#{key}"
    HTTPoison.get(url)
  end

  def test do
    get_locations_for_grid(49.3203, 50.0707, 11.1042, 9.7938, 7, 7)
  end

  def start do
    get_locations_for_grid(49.3203, 50.0707, 11.1042, 9.7938, 7, 7)
    |> IO.inspect()
    |> Enum.map(fn x ->
      {:ok, %HTTPoison.Response{body: body, status_code: 200}} = get_geo_for_location_name(x.name)
      :timer.sleep(1000)
      {:ok, decoded} = Poison.decode(body)
      location = List.first(decoded["results"])["geometry"]["location"]
      lat = location["lat"]
      lng = location["lng"]
      %{
        name: x.name,
        lat: lat,
        lng: lng,
        found_lat: x.lat,
        found_lng: x.lng
      } |> IO.inspect()
    end)
    |> IO.inspect()
  end

  def write_file do
    result = start() |> Poison.encode!()
    {:ok, file} = File.open("geo_processing_result.json", [:write])
    IO.binwrite(file, result)
    File.close(file)
  end

end
