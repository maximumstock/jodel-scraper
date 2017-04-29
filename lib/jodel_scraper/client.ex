defmodule JodelScraper.Client do

  @endpoint_v2  "https://api.go-tellm.com/api/v2/"
  @endpoint_v3  "https://api.go-tellm.com/api/v3/"
  @app_version  "android_4.42.5" # official JodelApp client version
  @client_id    "81e8a76e-1e02-4d17-9ba0-8a7020261b26" # static ID defined by JodelApp (see various client implementations on GitHub)
  @device_uid   "bda1edc56cda91a4945b5d6e07f23449c3c18d235759952807de15b68258171f" # presumably a randomly generated SHA256 hash

  # @client_id    "cd871f92-a23f-4afc-8fff-51ff9dc9184e" # Jodel client id (see various client implementations on GitHub)
  # @device_uid   "GgCwk3ElTfc3NAlX6zpnBLixKIsM4zHVWPrsUFGCeio%3D" # randomly generated SHA256 hash

  @max_jodels_per_request 100 # 100 seems to be the maximum

  require Logger


  # PUBLIC API
  def test_request do
    request_token(49.713862, 9.973702)
  end

  def extract_token({:ok, %HTTPoison.Response{body: body, status_code: 200}}) do
    body |> Poison.decode! |> Map.get("access_token")
  end

  def request_token(lat, lng, location_accuracy \\ 0) do

    login_url = @endpoint_v2 <> "users"
    body = authentication_data(lat, lng, location_accuracy)
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

  def get_jodels(token, feed, opts \\ []) do
    url = @endpoint_v2 <> "posts/location/" <> feed <> query(opts)
    headers = default_headers(token, "GET", url, "") ++ ["Authorization": "Bearer #{token}"]
    HTTPoison.get(url, headers)
  end

  def get_jodel_feed(token, feed, options \\ []) do
    get_jodels_perpetually(token, feed, "", [], false, options)
    # |> Enum.uniq_by(fn x -> x["post_id"] end)
  end

  def get_jodel_feed_with_comments(token, feed, options \\ []) do
    get_jodels_perpetually(token, feed, "", [], true, options)
    # |> Enum.uniq_by(fn x -> x["post_id"] end)
  end

  def get_single_jodel(token, jodel_id) do
    url = @endpoint_v2 <> "posts/" <> jodel_id
    headers = default_headers(token, "GET", url, "") ++ ["Authorization": "Bearer #{token}"]
    HTTPoison.get(url, headers)
  end

  def get_jodels_with_comments_for_jodels(token, jodels) do
    jodels
    |> Enum.map(fn x ->
        case __MODULE__.get_single_jodel(token, x["post_id"]) do
          {:ok, %{body: body, status_code: 200}} -> Poison.decode!(body)
          _ -> nil
        end
      end)
    |> Enum.filter(fn x -> x != nil end)
  end

  # HELPERS

  # Computes a HMAC signature hash for authentication purposes
  defp generate_hmac(token, method, url, body) do

    purl = URI.parse(url)
    raw = method <> "%" <> purl.host <> "%" <> Integer.to_string(purl.port) <> "%" <> purl.path <> "%" <> token <> "%" <> "#{DateTime.utc_now |> DateTime.to_string}" <> "%" <> "" <> "%" <> body
    # create HMAC SHA1 hash
    salt = :crypto.strong_rand_bytes(24) |> Base.encode16
    :crypto.hmac(:sha, salt, raw) |> Base.encode16 |> String.downcase

  end

  defp query(opts) do
    string = opts
    |> Enum.map(fn {key, value} -> "#{key}=#{value}" end)
    |> Enum.join("&")

    "?" <> string
  end

  defp authentication_data(lat, lng, loc_accuracy) do
    %{client_id: @client_id,
      device_uid: @device_uid,
      location: %{
        loc_accuracy: loc_accuracy,
        loc_coordinates: %{lat: lat, lng: lng}
      }
    } |> Poison.encode!
  end

  defp default_headers(token \\ "", method \\ "", url \\ "", body \\ "") do
    hmac = generate_hmac(token, method, url, body)
    [
      "Accept": "application/json; charset=utf-8",
      "User-Agent": "Jodel/" <> @app_version <> " Dalvik/2.1.0 (Linux; U; Android 6.0.1; Nexus 5 Build/MMB29V)",
      "X-Client-Type": @app_version,
      "X-Api-Version": "0.2",
      "X-Timestamp": DateTime.utc_now |> DateTime.to_string,
      "X-Authorization": "HMAC #{hmac}",
      "Content-Type": "application/json; charset=utf-8"
    ]
  end

  defp get_jodels_perpetually(token, feed, after_id, acc, with_comments, options) do
    options = options |> Keyword.put(:limit, @max_jodels_per_request) |> Keyword.put(:after, after_id)
    new_jodels = get_jodels(token, feed, options) |> extract_jodels
    # scrape until there is nothing left
    # length(<list>) < @max_jodels_per_request doesn't work,
    # as the number of returned jodels isn't always the same (see tests)
    if length(new_jodels) == 0 do
      case with_comments do
        true  -> get_jodels_with_comments_for_jodels(token, acc)
        _     -> acc
      end
    else
      last_jodel_id = new_jodels |> List.last |> Map.get("post_id")
      get_jodels_perpetually(token, feed, last_jodel_id, acc ++ new_jodels, with_comments, options)
    end
  end


  defp extract_jodels({:ok, %{status_code: 200, body: body}}) do
    body |> Poison.decode! |> Map.get("posts", [])
  end
  defp extract_jodels({:ok, %{status_code: status_code, body: body, headers: headers}})
    IO.inspect(headers)
    Logger.info("Error when loading jodels - #{status_code}")
    []
  end
  defp extract_jodels(_), do: []

end
