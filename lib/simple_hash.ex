alias Remixdb.Counter, as: Counter

defmodule Remixdb.SimpleHash do
  use GenServer

  @name :remixdb_simple_hash

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

  def hset(hash_name, key, val) do
    GenServer.call @name, {:hset, hash_name, key, val}
  end

  def hsetnx(hash_name, key, val) do
    GenServer.call @name, {:hsetnx, hash_name, key, val}
  end

  def hmset(hash_name, fields) do
    GenServer.call @name, {:hmset, hash_name, fields}
  end

  def hmget(hash_name, fields) do
    GenServer.call @name, {:hmget, hash_name, fields}
  end

  def hget(hash_name, key) do
    GenServer.call @name, {:hget, hash_name, key}
  end

  def hlen(hash_name) do
    GenServer.call @name, {:hlen, hash_name}
  end

  def hgetall(hash_name) do
    GenServer.call @name, {:hgetall, hash_name}
  end

  def hkeys(hash_name) do
    GenServer.call @name, {:hkeys, hash_name}
  end

  def hvals(hash_name) do
    GenServer.call @name, {:hvals, hash_name}
  end

  def hexists(hash_name, key) do
    GenServer.call @name, {:hexists, hash_name, key}
  end

  def hstrlen(hash_name, key) do
    GenServer.call @name, {:hstrlen, hash_name, key}
  end

  def hdel(hash_name, keys) do
    GenServer.call @name, {:hdel, hash_name, keys}
  end

  def hincrby(hash_name, key, amt) do
    GenServer.call @name, {:hincrby, hash_name, key, amt}
  end

  def rename(old_name, new_name) do
    GenServer.call @name, {:rename, old_name, new_name}
  end

  def handle_call({:hincrby, hash_name, key, amt}, _from, state) do
    old_map = Map.get(state, hash_name)

    new_val = Counter.incrby Map.get(old_map, key), amt
    new_map = Map.put(old_map, key, new_val)
    new_state = state |> Map.put(hash_name, new_map)

    {:reply, new_val, new_state}
    
  end

  def handle_call({:hdel, hash_name, keys}, _from, state) do
    old_map = Map.get(state, hash_name, Map.new)

    num_deleted = keys
    |> Enum.count(fn(kk) ->
      Map.has_key? old_map, kk
    end)

    new_map = keys
    |> Enum.reduce(old_map, fn(kk, acc) ->
      Map.delete(acc, kk)
    end)

    new_state = Map.put(state, hash_name, new_map)

    {:reply, num_deleted, new_state}
  end

  def handle_call({:hstrlen, hash_name, key}, _from, state) do
    res = Map.get(state, hash_name, Map.new)
    |> Map.get(key, "")
    |> :erlang.byte_size

    {:reply, res, state}
  end

  def handle_call({:hkeys, hash_name}, _from, state) do
    keys = state
    |> Map.get(hash_name, Map.new)
    |> Map.keys
    {:reply, keys, state}
  end

  def handle_call({:hvals, hash_name}, _from, state) do
    vals = state
    |> Map.get(hash_name, Map.new)
    |> Map.values

    {:reply, vals, state}
  end

  def handle_call({:hget, hash_name, key_name}, _from, state) do
    val = state
    |> Map.get(hash_name, Map.new)
    |> Map.get(key_name)

    {:reply, val, state}
  end

  def handle_call({:hgetall, hash_name}, _from, state) do
    vals = state
    |> Map.get(hash_name, Map.new)
    |> Enum.reduce([], fn({kk, vv}, acc) ->
      [kk|[vv|acc]]
    end)
    
    {:reply, vals, state}
  end

  def handle_call(:flushall, _from, _state) do
    {:reply, :ok, Map.new}
  end

  def handle_call({:hmget, hash_name, fields}, _from, state) do
    map = Map.get(state, hash_name, Map.new)

    res = fields
    |> Enum.map(fn(key) ->
      Map.get(map, key)
    end)

    {:reply, res, state}
  end

  def handle_call({:hmset, hash_name, fields}, _from, state) do
    old_map = state
    |> Map.get(hash_name, Map.new)

    fields_map = fields
    |> Enum.chunk_every(2)
    |> Map.new(fn([k, v]) ->
      {k, v}
    end)

    new_map = Map.merge(old_map, fields_map)

    new_state = Map.put(state, hash_name, new_map)

    {:reply, "OK", new_state}
  end

  def handle_call({:hsetnx, hash_name, key, val}, _from, state) do
    old_map = state |> Map.get(hash_name, Map.new)

    {res, new_state} = case Map.get(old_map, key, nil) do
                         nil ->
                           new_map = old_map |> Map.put(key, val)
                           new_state = Map.put(state, hash_name, new_map)
                           {1, new_state}
                         _ ->
                           {0, state}
                       end
    {:reply, res, new_state}

  end

  def handle_call({:hset, hash_name, key, val}, _from, state) do
    old_map = state
    |> Map.get(hash_name, Map.new)

    new_map = old_map
    |> Map.put(key, val)

    updated_state = state
    |> Map.put(hash_name, new_map)

    {:reply, key_inserted?(old_map, key), updated_state}
  end

  def handle_call(:dbsize, _from, state) do
    sz = state |> Map.keys |> Enum.count
    {:reply, sz, Map.new}
  end

  def handle_call({:hlen, hash_name}, _from, state) do
    sz = state |> Map.get(hash_name, Map.new) |> Enum.count
    {:reply, sz, state}
  end

  def handle_call({:hexists, hash_name, key}, _from, state) do
    res = state
    |> Map.get(hash_name, Map.new)
    |> has_key?(key)

    {:reply, res, state}
  end

  def handle_call({:rename, old_name, new_name}, _from, state) do
    {res, new_state} = Remixdb.Renamer.rename state, old_name, new_name
    {:reply, res, new_state}
  end

  defp key_inserted?(map, key) do
    case has_key?(map, key) do
      1 -> 0
      0 -> 1
    end
  end

  defp has_key?(hash, key) do
    case Map.has_key?(hash, key) do
      true -> 1
      _ -> 0
    end
  end
end
