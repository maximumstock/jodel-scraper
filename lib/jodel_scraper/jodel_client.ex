defmodule JodelClient do

  @moduledoc """
  This is a basic client implementation of the Jodel API.
  """

  @endpoint_v2  "https://api.go-tellm.com/api/v2/"
  # JodelApp client version
  # Major version has been set to "9", which is not the actual major version
  # See current Android version here:
  # https://play.google.com/store/apps/details?id=com.tellm.android.app&hl=de
  @app_version  "android_9.47.0"
  # static ID defined by JodelApp (see various client implementations on GitHub)
  @client_id "81e8a76e-1e02-4d17-9ba0-8a7020261b26"
  @max_jodels_per_request 100 # 100 seems to be the maximum


  """
  Public API
  """

  @doc """
  Requests a token for a given latitude and longitude.

  Returns a map (string keys) including the API response data.
  """
  def request_token(lat, lng, city \\ "", country_code \\ "", accuracy \\ 0) do
    url = @endpoint_v2 <> "users"
    data = auth_data(lat, lng, city, country_code, accuracy)
    hmac = generate_hmac("", "POST", url, data)
    headers = default_headers() ++ custom_headers([hmac: hmac])
    HTTPoison.post(url, data, headers)
  end

  def extract_token({:ok, response}), do: response |> Map.get(:body) |> Poison.decode! |> Map.get("access_token")
  def extract_posts({:ok, %HTTPoison.Response{body: body, status_code: 200}}) do
    body |> Poison.decode! |> Map.get("posts")
  end

  @doc """
  Acquires one batch of the specified feed - with or without comments.
  `opts` being a keyword list containing request options like:
  * `after`
  * `limit`

  Returns `{:ok, list}` with a list of all Jodels of this batch when successful
  and `{:error, reason}` when unsuccessful
  """
  def get_feed_batch(token, feed, opts \\ []) do
    url = @endpoint_v2 <> "posts/location/" <> map_feed_to_string(feed) <> query(opts)
    hmac = generate_hmac(token, "GET", url, "")
    headers = default_headers() ++ custom_headers([token: token, hmac: hmac])
    HTTPoison.get(url, headers)
  end

  @doc """
  Acquires the full specified feed - with or without comments.

  Returns `{:ok, list}` with a list of all Jodels when successful
  and `{:error, %HTTPoisonResponse}` when unsuccessful
  """
  def get_feed(token, feed) do
    get_feed_perpetually(token, feed, [], [limit: @max_jodels_per_request])
  end

  defp get_feed_perpetually(token, feed, acc, opts) do
    with  {:ok, response} <- get_feed_batch(token, feed, opts),
          %{body: body, status_code: 200} <- response,
          {:ok, decoded} <- Poison.decode(body),
          jodels <- Map.get(decoded, "posts")
    do
      if length(jodels) < @max_jodels_per_request do
        # we are done
        {:ok, acc ++ jodels}
      else
        last_jodel_id = jodels |> List.last |> Map.get("post_id")
        opts = opts |> Keyword.put(:after, last_jodel_id)
        get_feed_perpetually(token, feed, acc + jodels, opts)
      end
    else
      {:ok, %HTTPoison.Error{reason: reason}} -> {:error, reason}
      err -> {:error, err}
    end
  end

  @doc """
  Acquires a single Jodel with it's comments

  Returns `{:ok, map}` (string keys) containing all Jodel data when successful
  and `{:error, reason}` when unsuccessful
  """
  def get_single(token, id) do
    url = @endpoint_v2 <> "posts/" <> id
    hmac = generate_hmac(token, "GET", url, "")
    headers = default_headers() ++ custom_headers([token: token, hmac: hmac])
    HTTPoison.get(url, headers)
  end


  @doc """
  Retrieves full Jodels (with comments) for a list of Jodel IDs.

  Returns `{:ok, list}` witha list of all Jodels (with comments) when successful
  and `{:error, reason}` when unsuccessful
  """
  def get_comments_for_jodels(token, ids), do: Enum.map(ids, fn x -> get_single(token, x["post_id"]) end)


  """
  Private methods
  """

  defp generate_device_uid() do
    # bytes = :crypto.strong_rand_bytes(64)
    # :crypto.hash(:sha256, bytes) |> Base.encode16 |> String.downcase

    # only this one works:
    "bda1edc56cda91a4945b5d6e07f23449c3c18d235759952807de15b68258171f"
  end

  defp generate_hmac(token, method, url, body) do
    purl = URI.parse(url)
    raw = method <> "%" <> purl.host <> "%" <> Integer.to_string(purl.port) <> "%" <> purl.path <> "%" <> token <> "%" <> "#{DateTime.utc_now |> DateTime.to_string}" <> "%" <> "" <> "%" <> body
    # create HMAC SHA1 hash
    salt = :crypto.strong_rand_bytes(24) |> Base.encode16
    :crypto.hmac(:sha, salt, raw) |> Base.encode16
  end

  defp default_headers() do
    # all of the following headers are necessary! (as of 28-05-17)
    [
      "Accept": "application/json; charset=utf-8",
      "User-Agent": "Jodel/" <> @app_version <> " Dalvik/2.1.0 (Linux; U; Android 6.0.1; E6653 Build/32.2.A.0.305)",
      "X-Client-Type": @app_version,
      "X-Api-Version": "0.2",
      "Content-Type": "application/json; charset=utf-8",
      "X-Timestamp": DateTime.utc_now |> DateTime.to_string,
    ]
  end

  defp custom_headers(values), do: Enum.map(values, fn x -> map_custom_header(x) end)
  defp map_custom_header({:token, token}), do: {"Authorization", "Bearer #{token}"}
  defp map_custom_header({:hmac, hmac}), do: {"X-Authorization", "HMAC #{hmac}"}

  defp auth_data(lat, lng, city, country_code, accuracy) do
    %{
      client_id: @client_id,
      device_uid: generate_device_uid(),
      location: %{
        city: city,
        country: country_code,
        loc_accuracy: accuracy,
        loc_coordinates: %{lat: lat, lng: lng}
      }
    } |> Poison.encode!
  end

  defp map_feed_to_string(feed) do
    case feed do
      :popular    -> "popular"
      :discussed  -> "discussed"
      _           -> ""
    end
  end

  defp query(opts) do
    string = opts
    |> Enum.map(fn {key, value} -> "#{key}=#{value}" end)
    |> Enum.join("&")

    "?" <> string
  end



end
