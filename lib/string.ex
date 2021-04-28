alias Remixdb.Counter, as: Counter

defmodule Remixdb.String do
  use GenServer

  @name :remixdb_simple_string

  def start_link(_args) do
    GenServer.start_link __MODULE__, :ok, name: @name
  end

  def init(:ok) do
    {:ok, Map.new}
  end

  def flushall() do
    GenServer.call @name, :flushall
  end

  def dbsize() do
    GenServer.call @name, :dbsize
  end

  def set(key, val) do
    GenServer.call @name, {:set, key, val}
  end

  def getset(key, val) do
    GenServer.call @name, {:getset, key, val}
  end

  def get(key) do
    GenServer.call @name, {:get, key}
  end

  def rename(old_name, new_name) do
    GenServer.call @name, {:rename, old_name, new_name}
  end

  def append(key, val) do
    GenServer.call @name, {:append, key, val}
  end

  def incr(key) do
    GenServer.call @name, {:incrby, key, 1}
  end

  def incrby(key, vv) do
    {val, ""} = Integer.parse(vv)
    GenServer.call @name, {:incrby, key, val}
  end

  def decr(key) do
    GenServer.call @name, {:incrby, key, -1}
  end

  def decrby(key, vv) do
    {val, ""} = Integer.parse(vv)
    GenServer.call @name, {:incrby, key, val * -1}
  end

  def handle_call(:flushall, _from, _state) do
    {:reply, :ok, Map.new}
  end

  def handle_call(:dbsize, _from, state) do
    sz = state |> Map.keys |> Enum.count
    {:reply, sz, Map.new}
  end

  def handle_call({:append, key, val}, _from, state) do
    old_val = state |> Map.get(key)

    new_val = if old_val == nil do
      val
    else
      <<old_val::binary, val::binary>>
    end

    sz = new_val |> :erlang.byte_size
    new_state     = Map.put(state, key, new_val)
    {:reply, sz, new_state}
  end

  def handle_call({:incrby, key, incrby}, _from, state) do
    new_val = Counter.incrby get_val(state, key), incrby
    new_state = state |> Map.put(key, new_val)
    {:reply, new_val, new_state}
  end

  def handle_call({:get, key}, _from, state) do
    val = get_val(state, key)
    {:reply, val, state}
  end

  def handle_call({:getset, key, val}, _from, state) do
    old_val = get_val(state, key)
    new_state = state |> Map.put(key, val)
    {:reply, old_val, new_state}
  end

  def handle_call({:set, key, val}, _from, state) do
    new_state = state |> Map.put(key, val)
    {:reply, :ok, new_state}
  end

  def handle_call({:rename, old_name, new_name}, _from, state) do
    {res, new_state} = Remixdb.Renamer.rename state, old_name, new_name
    {:reply, res, new_state}
  end

  defp get_val(state, key) when is_map(state) do
    state |> Map.get(key)
  end
end
