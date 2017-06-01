defmodule TokenStore do
  use GenServer

  require Logger

  alias JodelClient, as: API

  def start_link do
    GenServer.start_link(__MODULE__, %{}, name: :tokenstore)
  end

  def init(state) do
    {:ok, state}
  end

  # Callbacks

  def handle_call({:token, %TokenStoreKey{} = key}, _from, state) do

    if contains?(state, key) do
      token = get_token(state, key)
      {:reply, {:ok, token}, state}
    else
      case acquire_token(key) do
        {:ok, token_data} ->
          token = token_data["access_token"]
          new_state = set_token(state, key, token)
          {:reply, {:ok, token}, new_state}
        {:error, reason}  -> {:reply, {:error, reason}, state}
      end
    end
  end

  # API

  def token(%TokenStoreKey{} = key) do
    GenServer.call(:tokenstore, {:token, key})
  end

  # Privates
  defp contains?(state, %TokenStoreKey{} = key) do
    case Map.get(state, key) do
      nil -> false
      _   -> true
    end
  end

  defp acquire_token(%TokenStoreKey{} = key) do
    case API.request_token(key.lat, key.lng, key.name, key.country_code, key.accuracy) do
      {:ok, %{body: body, status_code: 200}}    -> Poison.decode(body)
      {:ok, msg}                                -> {:error, msg}
      _                                         -> {:error, "unknown error"}
    end
  end

  defp get_token(state, %TokenStoreKey{} = key) do
    Map.get(state, key)
  end

  defp set_token(state, %TokenStoreKey{} = key, token) do
    Map.put(state, key, token)
  end

end
