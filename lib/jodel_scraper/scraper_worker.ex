defmodule ScraperWorker do
  use GenServer

  alias JodelClient, as: API
  alias JodelScraper.Jodel
  alias JodelScraper.Repo
  alias TokenStore

  require Logger

  def start_link(state, options \\ []) do
    GenServer.start_link(__MODULE__, state, options)
  end

  def init(state) do
    start(state)
    {:ok, state}
  end



  # Callbacks


  def handle_info(:work, state) do
    Logger.info("Scraping #{state.type} posts for #{state.location.city}")

    response = TokenStore.token(state.location)

    case response do
      {:ok, token} -> scrape(token, state.type)
      {:error, reason}  -> Logger.info("TokenStore could not acquire API token for #{state.location.city} (#{state.location.lat},#{state.location.lng}) (#{reason})")
    end

    schedule_scraping(state.interval)
    {:noreply, state}
  end



  # API

  defp start(state) do
    Logger.info("Init #{state.type}-scraper - #{state.location.city} (every #{state.interval}s)")
    schedule_scraping(0)
  end

  defp scrape(token, type) when is_bitstring(type) do
    API.get_all_jodels(token, type)
    |> process
    |> Enum.each(&(save_to_db &1))
  end

  defp scrape(token, type) when is_atom(type) do
    case type do
      :popular    -> scrape(token, "popular")
      :discussed  -> scrape(token, "discussed")
      _           -> scrape(token, "")
    end
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

    #Logger.info("Processing #{length(posts)} jodels")

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

  defp extract_token_data({:error, reason}), do: {:error, reason}
  defp extract_token_data({:ok, token}) do
    %{
      access_token: token["access_token"],
      distinct_id: token["distinct_id"],
      expiration_date: token["expiration_date"],
      refresh_token: token["refresh_token"]
    }
  end

end
