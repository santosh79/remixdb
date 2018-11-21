defmodule Remixdb.Hash do
  use GenServer
  def start(key_name) do
    GenServer.start_link __MODULE__, {:ok, key_name}, []
  end

  def init({:ok, key_name}) do
    {:ok, %{items: Map.new(), key_name: key_name}}
  end

  def hset(name, new_items) do
    GenServer.call name, {:hset, new_items}
  end

  def hincrby(name, field, val) do
    GenServer.call name, {:hincrby, field, val}
  end

  def hsetnx(name, field, val) do
    GenServer.call name, {:hsetnx, field, val}
  end

  def hlen(nil) do; 0; end
  def hlen(name) do
    GenServer.call name, :hlen
  end

  def hgetall(nil) do; []; end
  def hgetall(name) do
    GenServer.call name, :hgetall
  end

  def hdel(nil, _) do; 0; end
  def hdel(name, fields) do
    GenServer.call name, {:hdel, fields}
  end

  def hmget(nil, fields) do
    fields |> Enum.map(fn(_) -> :undefined end)
  end
  def hmget(name, fields) do
    GenServer.call name, {:hmget, fields}
  end

  def hmset(name, fields) do
    GenServer.call name, {:hmset, fields}
  end

  def hget(nil, _) do; :undefined; end
  def hget(name, field) do
    GenServer.call name, {:hget, field}
  end

  def hexists(nil, _) do; 0; end
  def hexists(name, field) do
    GenServer.call name, {:hexists, field}
  end

  def hstrlen(nil, _) do; 0; end
  def hstrlen(name, field) do
    GenServer.call name, {:hstrlen, field}
  end

  def hkeys(nil) do; []; end
  def hkeys(name) do
    GenServer.call name, :hkeys
  end

  def hvals(nil) do; []; end
  def hvals(name) do
    GenServer.call name, :hvals
  end

  def handle_call(:hkeys, _from, %{items: items} = state) do
    keys = items |> Map.keys
    {:reply, keys, state}
  end

  def handle_call(:hvals, _from, %{items: items} = state) do
    vals = items |> Map.values
    {:reply, vals, state}
  end

  def handle_call({:hstrlen, field}, _from, %{items: items} = state) do
    str_len = Map.get(items, field, "") |> String.length
    {:reply, str_len, state}
  end

  def handle_call({:hexists, field}, _from, %{items: items} = state) do
    exists = case Map.has_key?(items, field) do
      true -> 1
      _    -> 0
    end
    {:reply, exists, state}
  end

  def handle_call({:hmget, fields}, _from, %{items: items} = state) do
    results = fields |> Enum.map(fn(field) ->
      Map.get(items, field, :undefined)
    end)
    {:reply, results, state}
  end

  def handle_call({:hmset, fields}, _from, %{items: items} = state) do
    updated_items = to_map(fields)
    new_state     = update_state updated_items, state
    {:reply, "OK", new_state}
  end

  defp to_map(fields) do
    to_map fields, %{}
  end
  defp to_map([], acc) do; acc; end
  defp to_map([k,v|rest], acc) do
    to_map rest, Map.put(acc, k, v)
  end

  def handle_call({:hdel, fields}, _from, %{items: items} = state) do
    fields_set         = fields |> MapSet.new
    keys_that_remain   = items |> Map.keys |> MapSet.new |> MapSet.difference(fields_set)
    num_fields_removed = (items |> Map.keys |> Enum.count) - (keys_that_remain |> Enum.count)
    updated_items = keys_that_remain |> Enum.reduce(%{}, fn(key, acc) ->
      val = Map.get(items, key)
      Map.put(acc, key, val)
    end)

    new_state = update_state updated_items, state
    {:reply, num_fields_removed, new_state}
  end

  def handle_call({:hget, field}, _from, %{items: items} = state) do
    val = Map.get(items, field, :undefined)
    {:reply, val, state}
  end

  def handle_call({:hincrby, field, val}, _from, %{items: items} = state) do
    new_val       = Map.get(items, field, 0) + (val |> String.to_integer)
    updated_items = Map.put(items, field, new_val)
    new_state     = update_state updated_items, state
    {:reply, new_val, new_state}
  end

  def handle_call({:hsetnx, field, val}, _from, %{items: items} = state) do
    changed? = case Map.has_key?(items, field) do
      true -> 0
      _    -> 1
    end
    updated_items = Map.put(items, field, val)
    new_state     = update_state updated_items, state
    {:reply, changed?, new_state}
  end

  def handle_call({:hset, new_items}, _from, %{items: items} = state) do
    new_key = Map.keys(new_items) |> List.first
    return_val = case Map.has_key?(items, new_key) do
      true -> 0
      _    -> 1
    end
    updated_items = Map.merge items, new_items
    new_state     = update_state updated_items, state
    {:reply, return_val, new_state}
  end

  def handle_call(:hgetall, _from, %{items: items} = state) do
    result = items |> to_list
    {:reply, result, state}
  end

  def handle_call(:hlen, _from, %{items: items} = state) do
    num_items = items |> Map.keys |> Enum.count
    {:reply, num_items, state}
  end

  defp update_state(updated_items, state) do
    Map.merge(state, %{items: updated_items})
  end

  defp to_list(items) when is_map(items) do
    items |> Map.to_list |> flatten
  end
  defp flatten(items) do; flatten(items, []); end
  defp flatten([], acc) do; acc |> :lists.reverse; end
  defp flatten([h|t], acc) do
    {f,s} = h
    flatten t, [f|[s|acc]]
  end
end

