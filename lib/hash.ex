defmodule Remixdb.Hash do
  use GenServer
  def start(key_name) do
    GenServer.start __MODULE__, {:ok, key_name}, []
  end

  def init({:ok, key_name}) do
    {:ok, %{items: Map.new(), key_name: key_name}}
  end

  def hset(name, new_items) do
    GenServer.call name, {:hset, new_items}
  end

  def hlen(nil) do; 0; end
  def hlen(name) do
    GenServer.call name, :hlen
  end

  def hdel(nil, _) do; 0; end
  def hdel(name, fields) do
    GenServer.call name, {:hdel, fields}
  end

  def hget(nil, _) do; :undefined; end
  def hget(name, field) do
    GenServer.call name, {:hget, field}
  end

  def hexists(nil, _) do; 0; end
  def hexists(name, field) do
    GenServer.call name, {:hexists, field}
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

  def handle_call({:hexists, field}, _from, %{items: items} = state) do
    exists = case Map.has_key?(items, field) do
      true -> 1
      _    -> 0
    end
    {:reply, exists, state}
  end

  def handle_call({:hdel, fields}, _from, %{items: items} = state) do
    fields_set = fields |> MapSet.new
    keys_that_remain = items |> Map.keys |> MapSet.new |> MapSet.difference(fields_set)
    num_fields_removed = (items |> Map.keys |> Enum.count) - (keys_that_remain |> Enum.count)
    updated_items = keys_that_remain |> Enum.reduce(%{}, fn(key, acc) ->
      val = Dict.get(items, key)
      Dict.put(acc, key, val)
    end)

    new_state = update_state updated_items, state
    {:reply, num_fields_removed, new_state}
  end

  def handle_call({:hget, field}, _from, %{items: items} = state) do
    val = Map.get(items, field, :undefined)
    {:reply, val, state}
  end

  def handle_call({:hset, new_items}, _from, %{items: items} = state) do
    new_key = Map.keys(new_items) |> List.first
    return_val = case Map.has_key?(items, new_key) do
      true -> 0
      _    -> 1
    end
    updated_items = Dict.merge items, new_items
    new_state = update_state updated_items, state
    {:reply, return_val, new_state}
  end

  def handle_call(:hlen, _from, %{items: items} = state) do
    num_items = items |> Map.keys |> Enum.count
    {:reply, num_items, state}
  end

  defp update_state(updated_items, state) do
    Dict.merge(state, %{items: updated_items})
  end
end

