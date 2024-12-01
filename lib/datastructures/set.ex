defmodule Remixdb.Set do
  @moduledoc """
  A Redis-like set store implemented with GenServer.

  This module allows you to store and manipulate sets of unique values, similar to Redis' set commands. It supports operations such as adding and removing members, set unions, intersections, differences, and checking membership.

  ## Features

  - Store unique elements in sets identified by keys.
  - Perform union, intersection, and difference operations across multiple sets.
  - Retrieve set members, check membership, and move members between sets.
  - Rename sets and flush all stored sets.

  ## Example Usage

      iex> Remixdb.Set.start_link(:ok)
      {:ok, pid}
    
      iex> Remixdb.Set.sadd("myset", ["a", "b", "c"])
      3
    
      iex> Remixdb.Set.smembers("myset")
      ["a", "b", "c"]
    
      iex> Remixdb.Set.sismember("myset", "a")
      1
    
      iex> Remixdb.Set.sunion(["myset", "otherset"])
      ["a", "b", "c", "d"]
    
      iex> Remixdb.Set.flushall()
      :ok
  """
  use GenServer

  @name :remixdb_set

  @doc """
  Starts the `Remixdb.Set` GenServer.

  ## Parameters
  - `_args` (any): Arguments to initialize the GenServer (currently ignored).

  ## Returns
  - `{:ok, pid}` on success.

  ## Example Usage

      iex> Remixdb.Set.start_link(:ok)
      :ok
  """
  def start_link(_args) do
    GenServer.start_link __MODULE__, :ok, name: @name
  end

  def init(:ok) do
    {:ok, Map.new}
  end

  @doc """
  Flushes all sets and their members from the store.

  ## Returns
  - `:ok` on success.

  ## Example Usage

  iex> Remixdb.Set.flushall()
  :ok
  """
  def flushall() do
    GenServer.call @name, :flushall
  end

  @doc """
  Gets the total number of sets stored.

  ## Returns
  - The total number of stored sets as an integer.

  ## Example Usage

      iex> Remixdb.Set.dbsize()
      1
  """
  def dbsize() do
    GenServer.call @name, :dbsize
  end

  @doc """
  Adds one or more members to a set.

  ## Parameters
    - `name` (binary): The name of the set.
    - `items` (list): The items to add to the set.

  ## Returns
    - The number of elements added to the set.

  ## Example Usage
      iex> Remixdb.Set.sadd("myset", ["a", "b", "c"])
      3
  """
  def sadd(name, items) do
    GenServer.call @name, {:sadd, name, MapSet.new(items)}
  end

  @doc """
  Gets the number of members in a set.

  ## Parameters
    - `name` (binary): The name of the set.

  ## Returns
    - The number of members in the set as an integer.

  ## Example Usage

      iex> Remixdb.Set.scard("myset")
      3
  """
  def scard(name) do
    GenServer.call @name, {:scard, name}
  end

  @doc """
  Gets all members of a set.

  ## Parameters
    - `name` (binary): The name of the set.

  ## Returns
    - A list of members in the set.

  ## Example Usage

      iex> Remixdb.Set.smembers("myset")
      ["a", "b", "c"]
  """
  def smembers(name) do
    GenServer.call @name, {:smembers, name}
  end

  @doc """
  Checks if a value is a member of a set.

  ## Parameters
    - `name` (binary): The name of the set.
    - `val` (any): The value to check.

  ## Returns
    - `1` if the value is a member of the set.
    - `0` if the value is not a member.

  ## Example Usage

      iex> Remixdb.Set.sismember("myset", "a")
      1

      iex> Remixdb.Set.sismember("myset", "d")
      0
  """
  def sismember(name, val) do
    GenServer.call @name, {:sismember, name, val}
  end

  def smismember(name, keys) do
    GenServer.call @name, {:smismember, name, keys}
  end

  @doc """
  Performs the union of multiple sets.

  ## Parameters
    - `keys` (list): A list of set names to union.

  ## Returns
    - A list of all unique elements across the sets.

  ## Example Usage

      iex> Remixdb.Set.sunion(["set1", "set2"])
      ["a", "b", "c"]
  """
  def sunion(keys) do
    GenServer.call @name, {:sunion, keys}
  end

  @doc """
  Performs the intersection of multiple sets.

  ## Parameters
    - `keys` (list): A list of set names to intersect.

  ## Returns
    - A list of elements common to all sets.

  ## Example Usage

      iex> Remixdb.Set.sinter(["set1", "set2"])
      ["a"]
  """
  def sinter(keys) do
    GenServer.call @name, {:sinter, keys}
  end

  @doc """
  Performs the difference of multiple sets.

  ## Parameters
    - `keys` (list): A list of set names. The difference is calculated as `set1 - (set2 + set3 + ...)`.

  ## Returns
    - A list of elements in the first set but not in the others.

  ## Example Usage

      iex> Remixdb.Set.sdiff(["set1", "set2"])
      ["b", "c"]
  """
  def sdiff(keys) do
    GenServer.call @name, {:sdiff, keys}
  end

  @doc """
  Randomly selects a member from a set.

  ## Parameters
    - `set_name` (binary): The name of the set.

  ## Returns
    - A randomly selected member of the set, or `nil` if the set is empty.

  ## Example Usage

      iex> Remixdb.Set.srandmember("myset")
      "a"
  """
  def srandmember(set_name) do
    GenServer.call @name, {:srandmember, set_name}
  end

  @doc """
  Moves a member from one set to another.

  ## Parameters
    - `src` (binary): The source set name.
    - `dest` (binary): The destination set name.
    - `member` (any): The member to move.

  ## Returns
    - `1` if the member was successfully moved.
    - `0` if the member was not found in the source set.

  ## Example Usage

      iex> Remixdb.Set.smove("set1", "set2", "a")
      1
  """
  def smove(src, dest, member) do
    GenServer.call @name, {:smove, src, dest, member}
  end

  @doc """
  Checks if a set exists.

  ## Parameters
    - `set_name` (binary): The name of the set to check.

  ## Returns
    - `true` if the set exists.
    - `false` if the set does not exist.

  ## Example Usage

      iex> Remixdb.Set.exists?("myset")
      true
  
      iex> Remixdb.Set.exists?("unknownset")
      false
  """
  def exists?(set_name) do
    GenServer.call @name, {:exists, set_name}
  end
  
  @doc """
  Removes one or more members from a set.

  ## Parameters
    - `name` (binary): The name of the set.
    - `items` (list): The items to remove from the set.

  ## Returns
    - The number of elements successfully removed from the set.

  ## Example Usage

      iex> Remixdb.Set.srem("myset", ["a", "b"])
      2

      iex> Remixdb.Set.srem("myset", ["unknown"])
      0
  """
  def srem(name, items) do
    GenServer.call @name, {:srem, name, MapSet.new(items)}
  end

  @doc """
  Removes and returns a random member from a set.

  ## Parameters
    - `set_name` (binary): The name of the set.

  ## Returns
    - A randomly selected member of the set.
    - `nil` if the set is empty or does not exist.

  ## Example Usage

      iex> Remixdb.Set.spop("myset")
      "a"

      iex> Remixdb.Set.spop("emptyset")
      nil
  """
  def spop(set_name) do
    GenServer.call @name, {:spop, set_name}
  end

  @doc """
  Performs a union of multiple sets and stores the result in the first set.

  ## Parameters
    - `keys` (list): A list of set names. The union is calculated and stored in the first set in the list.

  ## Returns
    - The number of elements in the resulting set.

  ## Example Usage

      iex> Remixdb.Set.sunionstore(["set1", "set2"])
      5

      iex> Remixdb.Set.smembers("set1")
      ["a", "b", "c", "d", "e"]
  """
  def sunionstore(keys) do
    GenServer.call @name, {:sunionstore, keys}
  end

  @doc """
  Performs an intersection of multiple sets and stores the result in the first set.

  ## Parameters
    - `keys` (list): A list of set names. The intersection is calculated and stored in the first set in the list.

  ## Returns
    - The number of elements in the resulting set.

  ## Example Usage

      iex> Remixdb.Set.sinterstore(["set1", "set2"])
      2

      iex> Remixdb.Set.smembers("set1")
      ["c", "d"]
  """
  def sinterstore(keys) do
    GenServer.call @name, {:sinterstore, keys}
  end

  @doc """
  Performs a difference of multiple sets and stores the result in the first set.

  ## Parameters
    - `keys` (list): A list of set names. The difference is calculated as `set1 - (set2 + set3 + ...)` and stored in the first set in the list.

  ## Returns
    - The number of elements in the resulting set.

  ## Example Usage

      iex> Remixdb.Set.sdiffstore(["set1", "set2"])
      3

      iex> Remixdb.Set.smembers("set1")
      ["a", "b", "e"]
  """
  def sdiffstore(keys) do
    GenServer.call @name, {:sdiffstore, keys}
  end

  @doc """
  Renames a set.

  ## Parameters
    - `old_name` (binary): The current name of the set.
    - `new_name` (binary): The new name for the set.

  ## Returns
    - `true` if the rename was successful.
    - `false` if the set with the `old_name` does not exist.

  ## Example Usage

      iex> Remixdb.Set.rename("set1", "renamedset")
      true

      iex> Remixdb.Set.rename("unknownset", "newset")
      false
  """
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

  def handle_call({:smove, src, dest, member}, _from, state) do
    src_set = Map.get(state, src, MapSet.new)
    dest_set = Map.get(state, dest, MapSet.new)

    {upd_src_set, upd_dest_set, num_items_moved} = smove_helper(src_set, member, dest_set)

    new_state = state
    |> Map.delete(src)
    |> Map.put(src, upd_src_set)
    |> Map.delete(dest)
    |> Map.put(dest, upd_dest_set)

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

  defp smove_helper(src_set, member, dest_set) do
    case MapSet.member?(src_set, member) do
      false -> {src_set, dest_set, 0}
      _ ->
        upd_src_set = MapSet.delete(src_set, member)
        upd_dest_set = MapSet.put(dest_set, member)
        {upd_src_set, upd_dest_set, 1}
    end
  end
end
