defmodule JodelScraper.ScraperWorker do
  use GenServer

  alias JodelScraper.JodelApiClient, as: API
  alias JodelScraper.Jodel
  alias JodelScraper.Repo

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
    scrape(state.token.access_token, state.type);
    schedule_scraping(state.interval, Enum.random(1..30));
    {:noreply, state}
  end



  # API

  def start(state) do
    IO.puts("Started new #{state.type}-scraper for #{state.location.city} (every #{state.interval}s)")

    authenticate(state.location.city, state.location.lat, state.location.lng)
    |> update_token

    schedule_scraping(0, Enum.random(1..30))
  end

  def authenticate(city, lat, lng) do
    API.request_token(city, lat, lng)
    |> parse_successful_response
    |> extract_token_data
  end

  def update_token(token) do
    GenServer.cast(self(), {:update_token, token})
  end

  def scrape(token, type) do
    get_all_jodels(token, type)
    |> process
    |> save_to_db
  end

  def get_all_jodels(token, type) do
    get_all_jodels_perpetually(token, type, 100, 0, [])
  end

  defp get_all_jodels_perpetually(token, type, limit, skip, posts) do

    jodels = API.get_jodels(token, type, [limit: limit, skip: skip])
      |> parse_successful_response
      |> Map.get("posts")

    if length(jodels) == limit do
      get_all_jodels_perpetually(token, type, limit, limit + skip, posts ++ jodels)
    else
      posts ++ jodels
    end
  end

  defp schedule_scraping(interval, delay) do
    IO.puts("Scraping in #{interval + delay} seconds")
    Process.send_after(self(), :work, (interval + delay) * 1000)
  end

  defp save_to_db(posts) when is_list(posts), do: Enum.each(posts, fn p -> save_to_db(p) end)
  defp save_to_db(post) do

    case Repo.get(Jodel, post.post_id) do
      nil       -> Ecto.Changeset.change(%Jodel{}, post) # Post not found, we build one
      old_post  -> Ecto.Changeset.change(old_post, post) # Post exists, let's use it
    end
    |> Repo.insert_or_update

  end

  defp process(posts) do

    posts
    |> flatten_posts # list of posts with children -> list of lists of posts and children
    |> List.flatten # list of lists of posts and children -> list of posts and children
    |> Enum.map(&(transform_post &1)) # list of posts and children -> list of posts|children with the relevant data

  end

  defp flatten_posts(posts), do: Enum.map(posts, fn post -> flatten_post(post) end)

  defp flatten_post(%{"children" => _} = post), do: [post] ++ extract_post_comments(post)
  defp flatten_post(%{} = post), do: [post]

  defp extract_post_comments(%{"children" => []}), do: []
  defp extract_post_comments(%{"children" => nil}), do: []
  defp extract_post_comments(%{"children" => list, "post_id" => post_id}), do: Enum.map(list, fn e -> Map.put(e, "parent", post_id) end)
  defp extract_post_comments(_), do: []

  defp transform_post(post) do

    {:ok, created_at, 0} = post["created_at"] |> DateTime.from_iso8601
    {:ok, updated_at, 0} = post["updated_at"] |> DateTime.from_iso8601

    %{
      post_id: post["post_id"],
      message: post["message"],
      pin_count: post["pin_count"],
      hex_color: post["color"],
      distance: post["distance"],
      child_count: post["child_count"],
      is_image: post["is_image"] || false,
      vote_count: post["post_count"],
      location_name: post["location"]["name"],
      user_handle: post["user_handle"],
      image_url: post["image_url"],
      parent: post["parent"],
      created_at: created_at,
      updated_at: updated_at,
    }

  end

  defp parse_successful_response({:ok, %{body: body, status_code: 200}}) do
    body |> Poison.decode!
  end

  defp extract_token_data(token) do
    %{
      access_token: token["access_token"],
      distinct_id: token["distinct_id"],
      expiration_date: token["expiration_date"],
      refresh_token: token["refresh_token"]
    }
  end

end
