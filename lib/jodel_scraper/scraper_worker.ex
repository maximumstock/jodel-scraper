defmodule ScraperWorker do
  use GenServer

  alias JodelClient, as: API
  alias JodelScraper.Jodel
  alias JodelScraper.Repo

  require Logger

  def start_link(state, options \\ []) do
    GenServer.start_link(__MODULE__, state, options)
  end

  def init(state) do
    start(state)
    {:ok, state}
  end



  # Callbacks

  def handle_cast({:update_token, token}, state) do
    new_state = Map.put(state, :token, token)
    {:noreply, new_state}
  end

  def handle_info(:work, state) do
    Logger.info("Scraping #{state.type} posts for #{state.location.city}")

    case state.type do
      :popular    -> scrape(state.token.access_token, "popular")
      :discussed  -> scrape(state.token.access_token, "discussed")
      _           -> scrape(state.token.access_token, "")
    end

    schedule_scraping(state.interval)
    {:noreply, state}
  end



  # API

  def start(state) do
    Logger.info("Started new #{state.type}-scraper for #{state.location.city} (every #{state.interval}s)")

    authenticate(state.location.city, state.location.lat, state.location.lng)

    schedule_scraping(0)
  end

  def authenticate(city, lat, lng) do
    API.request_token(city, lat, lng)
    |> parse_response
    |> extract_token_data
    |> update_token
  end

  def update_token(token) do
    GenServer.cast(self(), {:update_token, token})
  end

  def scrape(token, type) do
    API.get_all_jodels(token, type)
    |> process
    |> Enum.each(&(save_to_db &1))
  end


  defp schedule_scraping(delay) do
    Process.send_after(self(), :work, delay * 1000)
  end

  defp save_to_db(post) do
    case Repo.get(Jodel, post.post_id) do
      nil       -> Ecto.Changeset.change(%Jodel{}, post) # Post not found, we build one
      old_post  -> Ecto.Changeset.change(old_post, post) # Post exists, let's use it
    end
    |> Repo.insert_or_update
  end

  defp process(posts) do

    Logger.info("Processing #{length(posts)} jodels")

    posts
    |> Enum.sort(fn (e1, e2) -> e1["updated_at"] >= e2["updated_at"] end) # sort in descending order
    |> Stream.uniq(fn e -> e["post_id"] end) # filter out all identical post_ids that appear second or later
    # now there should only be the most recent version for each post, assuming there were duplicates before
    |> Stream.flat_map(&(flatten_post &1)) # list of posts with children -> list of lists of posts and children
    |> Stream.map(&(transform_post &1)) # list of posts and children -> list of posts|children with the relevant data

  end

  defp flatten_post(%{"children" => _} = post), do: [post] ++ extract_post_comments(post)
  defp flatten_post(%{} = post), do: [post]

  defp extract_post_comments(%{"children" => nil}), do: [] # somehow needed, as some responses are malformed
  defp extract_post_comments(%{"children" => list, "post_id" => post_id}) do
    Enum.map(list, fn e -> Map.put(e, "parent", post_id) end)
  end
  defp extract_post_comments(_), do: []

  defp transform_post(post) do

    {:ok, created_at, 0} = post["created_at"] |> DateTime.from_iso8601
    {:ok, updated_at, 0} = post["updated_at"] |> DateTime.from_iso8601

    %{
      post_id: post["post_id"],
      message: post["message"],
      pin_count: Map.get(post, "pin_count", 0),
      hex_color: post["color"],
      distance: Map.get(post, "distance", 0),
      child_count: Map.get(post, "child_count", 0),
      vote_count: Map.get(post, "vote_count", 0),
      location_name: post["location"]["name"],
      user_handle: post["user_handle"],
      image_url: post["image_url"],
      parent: Map.get(post, "parent", nil),
      created_at: created_at,
      updated_at: updated_at,
    }

  end

  defp parse_response({:ok, %{body: body, status_code: 200}}) do
    body |> Poison.decode!
  end
  defp parse_response({type, %{status_code: status_code}}) do
    Logger.info("Error when authenticating #{status_code}")
    %{}
  end
  defp parse_response(_), do: %{}

  defp extract_token_data(%{}), do: %{}
  defp extract_token_data(token) do
    %{
      access_token: token["access_token"],
      distinct_id: token["distinct_id"],
      expiration_date: token["expiration_date"],
      refresh_token: token["refresh_token"]
    }
  end

end
