defmodule JodelScraper.JodelApiClient do

  @endpoint_v2  "https://api.go-tellm.com/api/v2/"
  @endpoint_v3  "https://api.go-tellm.com/api/v3/"
  @client_type  "android_4.29.1" # Android OS version?! (via JodelJS)
  @client_id    "81e8a76e-1e02-4d17-9ba0-8a7020261b26" # Android client id (via JodelJS)
  @device_uid   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855" # randomly generated SHA256 hash


  # Computes a HMAC signature hash for authentication purposes
  defp generate_hmac() do

    # build some message authentication code
    mac = "#{DateTime.utc_now |> DateTime.to_string}"
    # create HMAC SHA1 hash
    # salt does not have to be @client_id; was randomly chosen
    :crypto.hmac(:sha, mac, @client_id) |> Base.encode64

  end

  # Requests a new API token
  def get_api_token(country_code, city_name, city_lat, city_lng) do

    login_url = @endpoint_v2 <> "users"
    {:ok, payload} = Poison.encode(%{
      client_id: @client_id,
      device_uid: @device_uid,
      location: %{
        city: city_name,
        loc_accuracy: 1000.0,
        loc_coordinates: %{
          lat: city_lat,
          lng: city_lng
        },
        country: country_code
      }
    })

    hmac_signature = generate_hmac()
    headers = [
      "Accept": "application/json; charset=utf-8",
      "X-Client-Type": @client_type,
      "X-Api-Version": "0.2",
      "X-Timestamp": DateTime.utc_now |> DateTime.to_string,
      "X-Authorization": "HMAC #{hmac_signature}",
      "Content-Type": "application/json; charset=utf-8"
    ]

    HTTPoison.post(login_url, payload, headers)

  end

  def get_jodels(api_token, after_post_id \\ "", sort_order \\ "") do

    hmac_signature = generate_hmac()
    url = "#{@endpoint_v2}posts/location/#{sort_order}"
    query = [after: after_post_id]
    headers = [
      "Accept": "application/json; charset=utf-8",
      "Authorization": "Bearer #{api_token}",
      "X-Client-Type": @client_type,
      "X-Api-Version": "0.2",
      "X-Timestamp": DateTime.utc_now |> DateTime.to_string,
      "X-Authorization": "HMAC #{hmac_signature}",
      "Content-Type": "application/json; charset=utf-8"
    ]

    HTTPoison.get(url, headers, params: query)

  end

  def test_request do

    {:ok, %{body: body}} = get_api_token("DE", "Würzburg", 49.713862, 9.973702)
    {:ok, %{"access_token" => access_token}} = Poison.decode(body)
    {:ok, %{body: body}} = get_jodels(access_token, "", "popular")

    {:ok, posts} = Poison.decode(body)
    [first | trash] = posts["posts"]
    first["distance"]
    # first
    # is_map(posts)


  end

end
