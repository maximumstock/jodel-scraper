defmodule JodelScraper.JodelApiClient do

  @endpoint_v2  "https://api.go-tellm.com/api/v2/"
  @endpoint_v3  "https://api.go-tellm.com/api/v3/"
  @client_type  "android_4.29.1" # Android OS version?! (via JodelJS)
  @client_id    "81e8a76e-1e02-4d17-9ba0-8a7020261b26" # Jodel client id (see various client implementations on GitHub)
  @device_uid   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855" # randomly generated SHA256 hash

  # @client_id    "cd871f92-a23f-4afc-8fff-51ff9dc9184e" # Jodel client id (see various client implementations on GitHub)
  # @device_uid   "GgCwk3ElTfc3NAlX6zpnBLixKIsM4zHVWPrsUFGCeio%3D" # randomly generated SHA256 hash



  # Computes a HMAC signature hash for authentication purposes
  defp generate_hmac(method, url, token, body) do

    # build some message authentication code
    mac = method <> "%" <> url <> "%" <> token <> "%" <> "#{DateTime.utc_now |> DateTime.to_string}" <> "%" <> "" <> "%" <> body

    # create HMAC SHA1 hash
    :crypto.hmac(:sha, mac, @client_id) |> Base.encode16

  end

  defp query(opts) do
    string = opts
    |> Enum.map(fn {key, value} -> "#{key}=#{value}" end)
    |> Enum.join("&")

    "?" <> string
  end

  defp authentication_data(city, lat, lng) do

    %{client_id: @client_id,
      device_uid: @device_uid,
      location: %{
        city: city,
        loc_accuracy: 0.0,
        loc_coordinates: %{lat: lat, lng: lng},
        country: ""
      }
    } |> Poison.encode!

  end

  defp default_headers do

    hmac = generate_hmac("", "", "", "")
    [
      "Accept": "application/json; charset=utf-8",
      "X-Client-Type": @client_type,
      "X-Api-Version": "0.2",
      "X-Timestamp": DateTime.utc_now |> DateTime.to_string,
      "X-Authorization": "HMAC #{hmac}",
      "Content-Type": "application/json; charset=utf-8"
    ]

  end

  def request_token(city_name, lat, lng) do

    login_url = @endpoint_v2 <> "users"
    body = authentication_data(city_name, lat, lng)
    #hmac = generate_hmac("POST", login_url, "", body)
    headers = default_headers() #++ ["X-Authorization": "HMAC #{hmac}"]

    HTTPoison.post(login_url, body, headers)

  end

  def refresh_token(token, refresh_token, distinct_id) do

    url = @endpoint_v2 <> "users/refreshToken"
    body = %{
      "current_client_id" => @client_id,
      "distinct_id" => distinct_id,
      "refresh_token" => refresh_token
    }
    headers = default_headers() ++ ["Authorization": "Bearer #{token}"]

    HTTPoison.post(url, body, headers)

  end

  def get_jodels(token, type, opts \\ []) do

    url = @endpoint_v2 <> "posts/location/" <> type <> query(opts)
    #hmac = generate_hmac("GET", "posts", "", "")
    headers = default_headers() ++ ["Authorization": "Bearer #{token}"]

    HTTPoison.get(url, headers)

  end

  def test_request do

    request_token("Würzburg", 49.713862, 9.973702)

  end

end
