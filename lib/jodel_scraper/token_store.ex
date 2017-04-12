defmodule TokenStore do
  use GenServer

  require Logger

  alias JodelClient

  def start_link do
    GenServer.start_link(__MODULE__, %{}, name: :tokenstore)
  end

  def init(state) do
    {:ok, state}
  end

  # Callbacks

  def handle_call({:token, key}, _from, state) do

    if contains?(state, key) do
      {:reply, {:ok, get_token(state, key)}, state}
    else
      case acquire_token(key) do
        {:ok, token_data} -> {:reply, {:ok, token_data["access_token"]}, set_token(state, key, token_data["access_token"])}
        {:error, reason}  -> {:reply, {:error, reason}, state}
      end
    end
  end

  # API

  def token(key) do
    GenServer.call(:tokenstore, {:token, key})
  end

  # Privates
  defp contains?(state, key) do
    case Map.get(state, key) do
      nil -> false
      _   -> true
    end
  end

  defp acquire_token(key) do
    case JodelClient.request_token(key.lat, key.lng) do
      {:ok, %{body: body, status_code: 200}}  -> Poison.decode(body)
      {:ok, %{status_code: status_code}}      -> {:error, status_code}
      _                                       -> {:error, "unknown error"}
    end
  end

  defp get_token(state, key) do
    Map.get(state, key)
  end

  defp set_token(state, key, token) do
    Map.put(state, key, token)
  end

end
