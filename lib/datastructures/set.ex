defmodule Remixdb.Set do
  use GenServer

  @name :remixdb_set

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

  def sadd(name, items) do
    GenServer.call @name, {:sadd, name, MapSet.new(items)}
  end

  def scard(name) do
    GenServer.call @name, {:scard, name}
  end

  def smembers(name) do
    GenServer.call @name, {:smembers, name}
  end

  def sismember(name, val) do
    GenServer.call @name, {:sismember, name, val}
  end

  def smismember(name, keys) do
    GenServer.call @name, {:smismember, name, keys}
  end

  def sunion(keys) do
    GenServer.call @name, {:sunion, keys}
  end

  def sinter(keys) do
    GenServer.call @name, {:sinter, keys}
  end

  def sdiff(keys) do
    GenServer.call @name, {:sdiff, keys}
  end

  def srandmember(set_name) do
    GenServer.call @name, {:srandmember, set_name}
  end

  def smove(src, dest, member) do
    GenServer.call @name, {:smove, src, dest, member}
  end

  def exists?(set_name) do
    GenServer.call @name, {:exists, set_name}
  end
  
  def srem(name, items) do
    GenServer.call @name, {:srem, name, MapSet.new(items)}
  end

  def spop(set_name) do
    GenServer.call @name, {:spop, set_name}
  end

  def sunionstore(keys) do
    GenServer.call @name, {:sunionstore, keys}
  end

  def sinterstore(keys) do
    GenServer.call @name, {:sinterstore, keys}
  end

  def sdiffstore(keys) do
    GenServer.call @name, {:sdiffstore, keys}
  end

  def rename(old_name, new_name) do
    GenServer.call @name, {:rename, old_name, new_name}
  end

  def handle_call(:flushall, _from, _state) do
    {:reply, :ok, Map.new}
  end

  def handle_call(:dbsize, _from, state) do
    sz = state |> Map.keys |> Enum.count
    {:reply, sz, Map.new}
  end

  def handle_call({:smembers, name}, _from, state) do
    members = Map.get(state, name, MapSet.new) |> Enum.into([])
    {:reply, members, state}
  end

  def handle_call({:sadd, name, new_items}, _from, state) do
    old_sz = Map.get(state, name, MapSet.new) |> Enum.count

    new_set = Map.get(state, name, MapSet.new)
    |> MapSet.union(new_items)

    new_state = Map.put(state, name, new_set)

    new_sz = new_set |> Enum.count

    num_items_added = (new_sz - old_sz)
    {:reply, num_items_added, new_state}
  end

  # SantoshTODO: Clean this up
  def handle_call({:sunion, set_names}, _from, state) when is_list(set_names) do
    res = get_sets(set_names, state)
    |> union
    |> Enum.into([])

    {:reply, res, state}
  end


  def handle_call({:sinter, set_names}, _from, state) when is_list(set_names) do
    sets = get_sets(set_names, state)

    first_set = List.first sets

    res = sets
    |> Enum.drop(1)
    |> Enum.reduce(first_set, &MapSet.intersection/2)
    |> Enum.into([])

    {:reply, res, state}
  end

  def handle_call({:sdiff, set_names}, _from, state) when is_list(set_names) do
    res = do_sdiff set_names, state
    {:reply, res, state}
  end

  def handle_call({:scard, name}, _from, state) do
    sz = Map.get(state, name, MapSet.new) |> Enum.count
    {:reply, sz, state}
  end

  def handle_call({:sismember, name, val}, _from, state) do
    res = state
    |> Map.get(name, MapSet.new)
    |> is_member?(val)

    {:reply, res, state}
  end

  def handle_call({:srandmember, set_name}, _from, state) do
    rand_item = state |> Map.get(set_name) |> get_rand_item 
    {:reply, rand_item, state}
  end

  # SantoshTODO: Clean this up
  def handle_call({:smove, src, dest, member}, _from, state) do
    src_set = Map.get(state, src, MapSet.new)

    {new_state, num_items_moved} = case MapSet.member?(src_set, member) do
                                     false -> {state, 0}
                                     true -> 
                                       updated_src_set = MapSet.delete(src_set, member)
                                       updated_dest_set = Map.get(state, dest, MapSet.new) |>
                                         MapSet.put(member)
                                       ns = case Enum.empty?(updated_src_set) do
                                              true -> Map.delete(state, src)
                                              false -> Map.put(state, src, updated_src_set)
                                            end |> Map.put(dest, updated_dest_set)
                                       {ns, 1}
                                   end

    {:reply, num_items_moved, new_state}
  end

  # SantoshTODO: Figure out a way to re-factor this
    def handle_call({:exists, set_name}, _from, state) do
      res = !! Map.get(state, set_name, nil)
      {:reply, res, state}
    end

    def handle_call({:srem, name, new_items}, _from, state) do
      old_set = Map.get(state, name, MapSet.new)

      new_state = update_state(MapSet.difference(old_set, new_items), name, state)

      old_sz = old_set |> Enum.count
      new_sz = new_state |> Map.get(name) |> Enum.count

      {:reply, (old_sz - new_sz), new_state}
    end

    def handle_call({:spop, set_name}, _from, state) do
      items = state |> Map.get(set_name)
      case (items |> get_rand_item) do
        nil ->
          {:reply, nil, state}
        rand_item ->
          new_items = items |> MapSet.new |> MapSet.delete(rand_item)
          new_state = Map.put(state, set_name, new_items)
          {:reply, rand_item, new_state}
      end
    end

    # SantoshTODO: Figure out a way to re-factor this
    def handle_call({:sunionstore, keys}, _from, state) do
      res = keys |>
        Enum.map(fn(kk) ->
          Map.get(state, kk, MapSet.new)
        end)
        |> union

      first_key = keys |> List.first
      num_items = res |> Enum.count
      new_state = state |> Map.put(first_key, res)

      {:reply, num_items, new_state}
    end

    def handle_call({:sinterstore, keys}, _from, state) do
      res = keys |>
        Enum.drop(1) |>
        Enum.map(fn(kk) ->
          Map.get(state, kk, MapSet.new)
        end)
        |> intersection

      first_key = keys |> List.first
      num_items = res |> Enum.count
      new_state = state |> Map.put(first_key, res)

      {:reply, num_items, new_state}
    end

    def handle_call({:sdiffstore, keys}, _from, state) do
      res = do_sdiff(keys |> Enum.drop(1), state)
      new_state = state |> Map.put(List.first(keys), res)
      num_items = res |> Enum.count

      {:reply, num_items, new_state}
    end

    def handle_call({:smismember, name, keys}, _from, state) do
      set = Map.get(state, name, MapSet.new)
      res = keys
      |> Enum.map(&(is_member?(set, &1)))

      {:reply, res, state}
    end

    def handle_call({:rename, old_name, new_name}, _from, state) do
      {res, new_state} = Remixdb.Renamer.rename state, old_name, new_name
      {:reply, res, new_state}
    end

    defp update_state(items, name, state) do
      state |> Map.put(name, items)
    end

    defp union(sets) when is_list(sets) do
      sets |> Enum.reduce(MapSet.new, &MapSet.union/2)
    end

    defp intersection(sets) when is_list(sets) do
      sets
      |> Enum.drop(1)
      |> Enum.reduce(List.first(sets), &MapSet.intersection/2)
    end
    
    defp get_sets(set_names, state) when is_list(set_names) do
      set_names
      |> Enum.map(fn(x) ->
        Map.get(state, x, MapSet.new)
      end)
    end

    defp get_rand_item(nil) do
      nil
    end

    defp get_rand_item(st) do
      case Enum.empty?(st) do
        true -> nil
        _ -> Enum.random(st)
      end
    end

    defp do_sdiff(set_names, state) do
      sets = get_sets(set_names, state)

      first_set = List.first(sets)
      rest_sets  = sets |> Enum.drop(1) |> union

      MapSet.difference(first_set, rest_sets)
      |> Enum.into([])
    end

    defp is_member?(set, key) do
      case MapSet.member?(set, key) do
        true -> 1
        _ -> 0
      end
    end
end
