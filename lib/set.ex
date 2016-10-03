defmodule Remixdb.Set do
  use GenServer
  def start(key_name) do
    GenServer.start_link __MODULE__, {:ok, key_name}, []
  end

  def init({:ok, key_name}) do
    {:ok, %{items: MapSet.new(), key_name: key_name}}
  end

  def sadd(name, items) do
    GenServer.call name, {:sadd, MapSet.new(items)}
  end

  def srem(nil, items) do; 0; end
  def srem(name, items) do
    GenServer.call name, {:srem, MapSet.new(items)}
  end

  def smembers(nil) do; []; end
  def smembers(name) do
    GenServer.call name, :smembers
  end

  def sismember(nil, _val) do; 0; end
  def sismember(name, val) do
    GenServer.call name, {:sismember, val}
  end

  def scard(nil) do; 0; end
  def scard(name) do
    GenServer.call name, :scard
  end

  def smove(src, dest, member) do
    GenServer.call dest, {:smove, src, member}
  end

  def srandmember(nil) do; :undefined; end
  def srandmember(name) do
    GenServer.call name, :srandmember
  end

  def spop(nil) do; :undefined; end
  def spop(name) do
    GenServer.call name, :spop
  end

  def sunion(names) do
    names
    |> Remixdb.Misc.pmap(&Remixdb.Set.smembers/1)
    |> Enum.reduce(MapSet.new, fn(el, acc) ->
      el |> Enum.into(MapSet.new) |> MapSet.union(acc)
    end)
    |> Enum.into([])
  end

  def sinter([nil|rest]) do; []; end
  def sinter(items) do
    first_item = items |> List.first |> Remixdb.Set.smembers |> MapSet.new

    items
    |> Enum.map(&Remixdb.Set.smembers/1)
    |> Enum.reduce(first_item, fn(item, acc) ->
      item
      |> Enum.into(MapSet.new)
      |> MapSet.intersection(acc)
    end)
    |> Enum.into([])
  end

  def sdiff([nil|rest]) do; []; end
  def sdiff([first|rest]) do
    first_elements = first |> Remixdb.Set.smembers |> MapSet.new
    rest_elements  = rest |> Remixdb.Set.sunion |> MapSet.new
    MapSet.difference(first_elements, rest_elements) |>
    Enum.into([])
  end

  def sunionstore(dest, keys) do
   GenServer.call dest, {:sunionstore, keys}
  end

  def sdiffstore(dest, keys) do
    GenServer.call dest, {:sdiffstore, keys}
  end

  def sinterstore(dest, keys) do
    GenServer.call dest, {:sinterstore, keys}
  end

  def handle_call({:sunionstore, keys}, _from, state) do
    {num_items, new_state} = perform_store_command &Remixdb.Set.sunion/1, keys, state
    {:reply, num_items, new_state}
  end

  def handle_call({:sdiffstore, keys}, _from, %{items: items} = state) do
    {num_items, new_state} = perform_store_command &Remixdb.Set.sdiff/1, keys, state
    {:reply, num_items, new_state}
  end

  def handle_call({:sinterstore, keys}, _from, state) do
    {num_items, new_state} = perform_store_command &Remixdb.Set.sinter/1, keys, state
    {:reply, num_items, new_state}
  end

  def handle_call(:smembers, _from, %{items: items} = state) do
    members = items |> Enum.into([])
    {:reply, members, state}
  end

  def handle_call({:sadd, new_items}, _from, %{items: items} = state) do
    num_items_added = MapSet.difference(new_items, items) |> Enum.count
    updated_items   = MapSet.union(items, new_items)
    new_state       = update_state updated_items, state
    {:reply, num_items_added, new_state}
  end

  def handle_call({:srem, new_items}, _from, %{items: items} = state) do
    num_items_removed = MapSet.intersection(items, new_items) |> Enum.count
    new_items         = MapSet.difference(items, new_items)
    new_state         = new_items |> update_state(state)
    Remixdb.Keys.popped_out? new_items, self
    {:reply, num_items_removed, new_state}
  end

  def handle_call(:scard, _from, %{items: items} = state) do
    num_items = items |> Enum.count
    {:reply, num_items, state}
  end

  def handle_call(:srandmember, _from, %{items: items} = state) do
    rand_item = items |> get_rand_item 
    {:reply, rand_item, state}
  end

  def handle_call(:spop, _from, %{items: items} = state) do
    rand_item = items |> get_rand_item
    new_items = items |> MapSet.new |> MapSet.delete(rand_item)
    new_state = new_items |> update_state(state)
    Remixdb.Keys.popped_out? new_items, self
    {:reply, rand_item, new_state}
  end

  def handle_call({:sismember, val}, _from, %{items: items} = state) do
    present = case MapSet.member?(items, val) do
      true  -> 1
      false -> 0
    end
    {:reply, present, state}
  end

  def handle_call({:smove, src, member}, _from, %{items: items} = state) do
    {num_items_moved, new_items} = case Remixdb.Set.srem(src, [member]) do
      1 -> {1, MapSet.put(items, member)}
      0 -> {0, items}
    end
    new_state = new_items |> update_state(state)
    Remixdb.Keys.popped_out? new_items, self
    {:reply, num_items_moved, new_state}
  end

  def handle_cast(:stop, state) do
    {:stop, :normal, state}
  end

  # SantoshTODO: Use supervisors for this
  def terminate(:normal, %{key_name: key_name}) do
    Remixdb.KeyHandler.remove key_name
    :ok
  end

  defp get_rand_item(items) do
    items |> Enum.shuffle |> Enum.take(1) |> List.first
  end

  defp update_state(updated_items, state) do
    Dict.merge(state, %{items: updated_items})
  end

  defp perform_store_command(func, keys, %{items: items} = state) do
    result = func.(keys) |> MapSet.new
    num_items = result |> Enum.count
    new_state = update_state result, state
    {num_items, new_state}
  end

end

