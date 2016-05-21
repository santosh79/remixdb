defmodule Remixdb.Set do
  use GenServer
  def start(key_name) do
    GenServer.start __MODULE__, {:ok, key_name}, []
  end

  def init({:ok, key_name}) do
    {:ok, %{items: MapSet.new(), key_name: key_name}}
  end

  def sadd(name, items) do
    GenServer.call name, {:sadd, MapSet.new(items)}
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

  def handle_call(:smembers, _from, %{items: items} = state) do
    members = items |> Enum.into([])
    {:reply, members, state}
  end

  def handle_call({:sadd, new_items}, _from, %{items: items} = state) do
    num_items_added = MapSet.difference(new_items, items) |> Enum.count
    updated_items = MapSet.union(items, new_items)
    new_state = update_state updated_items, state
    {:reply, num_items_added, new_state}
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
    Remixdb.Set.popped_out? self, (new_items |> Enum.count)
    {:reply, rand_item, new_state}
  end

  def handle_call({:sismember, val}, _from, %{items: items} = state) do
    present = case MapSet.member?(items, val) do
      true  -> 1
      false -> 0
    end
    {:reply, present, state}
  end

  def terminate(:normal, _state) do; :ok; end

  defp get_rand_item(items) do
    items |> Enum.shuffle |> Enum.take(1) |> List.first
  end

  defp update_state(updated_items, state) do
    Dict.merge(state, %{items: updated_items})
  end

  def popped_out?(name, 0) do
    spawn(fn ->
      GenServer.stop(name, :normal)
    end)
  end
  def popped_out?(name, _) do; :void; end
end

