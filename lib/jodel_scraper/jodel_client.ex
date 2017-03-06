defmodule JodelClient do

  @endpoint_v2  "https://api.go-tellm.com/api/v2/"
  # @endpoint_v3  "https://api.go-tellm.com/api/v3/"
  @app_version  "android_4.29.1" # Android OS version?! (via JodelJS)
  @secret       "iyWpGGuOOCdKIMRsfxoJMIPsmCFdrscSxGyCfmBb"
  @client_id    "81e8a76e-1e02-4d17-9ba0-8a7020261b26" # Jodel client id (see various client implementations on GitHub)
  @device_uid   "bda1edc56cda91a4945b5d6e07f23449c3c18d235759952807de15b68258171f" #"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855" # randomly generated SHA256 hash

  # @client_id    "cd871f92-a23f-4afc-8fff-51ff9dc9184e" # Jodel client id (see various client implementations on GitHub)
  # @device_uid   "GgCwk3ElTfc3NAlX6zpnBLixKIsM4zHVWPrsUFGCeio%3D" # randomly generated SHA256 hash

  @max_jodels_per_request 100


  # PUBLIC API
  def test_request do
    request_token("Würzburg", 49.713862, 9.973702)
  end

  def request_token(city_name, lat, lng) do

    login_url = @endpoint_v2 <> "users"
    body = authentication_data(city_name, lat, lng)
    headers = default_headers("", "POST", login_url, body)

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
    headers = default_headers() ++ ["Authorization": "Bearer #{token}"]
    HTTPoison.get(url, headers)
  end

  def get_all_jodels(token, type) do
    get_all_jodels_perpetually(token, type, "", [])
  end

  # HELPERS

  # Computes a HMAC signature hash for authentication purposes
  defp generate_hmac(token, method, url, body) do

    purl = URI.parse(url)
    raw = method <> "%" <> purl.host <> "%" <> Integer.to_string(purl.port) <> "%" <> purl.path <> "%" <> token <> "%" <> "#{DateTime.utc_now |> DateTime.to_string}" <> "%" <> "" <> "%" <> body
    # create HMAC SHA1 hash
    :crypto.hmac(:sha, raw, @secret) |> Base.encode16 |> String.downcase
    #"1ddbf34d9b3f38d9cc2297a1fbfbb8ff2b681d1b"

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

  defp default_headers(token \\ "", method \\ "", url \\ "", body \\ "") do

    hmac = generate_hmac(token, method, url, body)

    IO.inspect [
      "Accept": "application/json; charset=utf-8",
      #"User-Agent": "node-superagent/3.3.1",
      "User-Agent": "Jodel/" <> @app_version <> " Dalvik/2.1.0 (Linux; U; Android 6.0.1; Nexus 5 Build/MMB29V)",
      "X-Client-Type": @app_version,
      "X-Api-Version": "0.2",
      "X-Timestamp": DateTime.utc_now |> DateTime.to_string,
      "X-Authorization": "HMAC #{hmac}",
      "Content-Type": "application/json; charset=utf-8"
    ]

  end

  defp get_all_jodels_perpetually(token, type, after_id, acc) do
    new_jodels = get_jodels_safe(token, type, [limit: @max_jodels_per_request, after: after_id])
    if length(new_jodels) == 0 do
      acc
    else
      last_jodel_id = new_jodels |> List.last |> Map.get("post_id")
      get_all_jodels_perpetually(token, type, last_jodel_id, acc ++ new_jodels)
    end
  end


  defp get_jodels_safe(token, type, opts) do
    # this is definitely a list (either filled or empty)
    get_jodels(token, type, opts) |> extract_jodels
  end

  defp extract_jodels({:ok, %{status_code: 200, body: body}}) do
    Poison.decode!(body) |> Map.get("posts", [])
  end
  defp extract_jodels(_), do: []

end
