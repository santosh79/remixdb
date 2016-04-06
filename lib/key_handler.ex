defmodule Remixdb.KeyHandler do
  use GenServer

  def start_link do
    GenServer.start_link __MODULE__, :ok, [name: :remixdb_key_handler]
  end

  def init(:ok) do
    Process.flag :trap_exit, true
    {:ok, %{}}
  end

  def exists?(key) do
    GenServer.call :remixdb_key_handler, {:exists, key}
  end

  def get(key) do
    GenServer.call :remixdb_key_handler, {:get, key}
  end

  def set(key, val) do
    GenServer.call :remixdb_key_handler, {:set, key, val}
  end

  def append(key, val) do
    GenServer.call :remixdb_key_handler, {:append, key, val}
  end

  def dbsize do
    GenServer.call :remixdb_key_handler, :dbsize
  end

  def flushall do
    GenServer.call :remixdb_key_handler, :flushall
  end

  def handle_call({:append, key, val}, _from, state) do
    key_name = key |> get_key_name
    new_val = Remixdb.String.append key_name, key, val
    string_length = new_val |> String.length
    {:reply, string_length, state}
  end

  def handle_call({:set, key, val}, _from, state) do
    key_name = key |> get_key_name
    new_key = false
    key_pid = case (key |> get_key_pid) do
      nil ->
        new_key = true
        Remixdb.SimpleServer.start key_name, Remixdb.String
        Process.whereis key_name
        pid -> pid
    end
    Remixdb.String.set key_name, key, val
    new_state = case new_key do
      true ->
        Dict.put(state, key_name, key_pid)
        false -> state
    end
    {:reply, :ok, new_state}
  end

  def handle_call({:get, key}, _from, state) do
    val = case(key |> get_key_pid) do
      nil -> nil
      key_pid -> 
      key |> get_key_name |>
      Remixdb.String.get(key)
    end
    {:reply, val, state}
  end

  def handle_call({:exists, key}, _from, state) do
    val = !!(key |> get_key_pid)
    {:reply, val, state}
  end

  def handle_call(:dbsize, _from, state) do
    count = state |> Dict.keys |> Enum.count
    {:reply, count, state}
  end

  def handle_call(:flushall, _from, state) do
    state |> Dict.values |> Enum.each(fn(pid) ->
      Process.exit(pid, :kill)
    end)
    {:reply, :ok, %{}}
  end

  defp get_key_pid(key) do
    key |> get_key_name |> Process.whereis
  end

  defp get_key_name(key) do
    ("remixdb_string|" <> key) |> String.to_atom
  end
end

