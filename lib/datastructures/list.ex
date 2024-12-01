defmodule Remixdb.List do
  @moduledoc """
  A Redis-like list store implemented with GenServer.

  This module provides operations similar to Redis lists, such as:
  - Adding elements to the left or right of a list.
  - Popping elements from the left or right of a list.
  - Getting elements by index, range, or trimming the list.
  - Renaming keys and flushing all data.

  ## Features

  - Store and manipulate lists identified by keys.
  - Perform atomic list operations via GenServer.
  - Useful for in-memory data structures with list semantics.

  ## Example Usage

      iex> Remixdb.List.start_link(:ok)
      {:ok, pid}

      iex> Remixdb.List.rpush("mylist", ["a", "b", "c"])
      3

      iex> Remixdb.List.lrange("mylist", 0, -1)
      ["a", "b", "c"]

      iex> Remixdb.List.lpop("mylist")
      "a"

      iex> Remixdb.List.rpoplpush("mylist", "anotherlist")
      "c"

      iex> Remixdb.List.dbsize()
      2
  """

  use GenServer

  @name :remixdb_list

  @doc """
  Starts the `Remixdb.List` GenServer.

  ## Parameters
    - `_args` (any): Arguments for the GenServer (currently ignored).

  ## Returns
    - `{:ok, pid}` on success.

  ## Example Usage

      iex> Remixdb.List.start_link(:ok)
  """
  def start_link(_args) do
    GenServer.start_link(__MODULE__, :ok, name: @name)
  end

  def init(:ok) do
    {:ok, Map.new()}
  end

  @doc """
  Flushes all lists in the store.

  ## Returns
    - `:ok` on success.

  ## Example Usage

      iex> Remixdb.List.flushall()
      :ok
  """
  def flushall() do
    GenServer.call(@name, :flushall)
  end

  @doc """
  Gets the total number of lists in the store.

  ## Returns
    - The size of the database as an integer.

  ## Example Usage

      iex> Remixdb.List.dbsize()
      2
  """
  def dbsize() do
    GenServer.call(@name, :dbsize)
  end

  @doc """
  Gets the length of a list.

  ## Parameters
    - `list_name` (binary): The name of the list.

  ## Returns
    - The number of elements in the list.

  ## Example Usage

      iex> Remixdb.List.llen("mylist")
      3
  """
  def llen(list_name) do
    GenServer.call(@name, {:llen, list_name})
  end

  @doc """
  Gets a range of elements from a list.

  ## Parameters
    - `list_name` (binary): The name of the list.
    - `start` (integer): The start index (inclusive).
    - `stop` (integer): The stop index (inclusive).

  ## Returns
    - A list of elements in the specified range.

  ## Example Usage

      iex> Remixdb.List.lrange("mylist", 0, -1)
      ["a", "b", "c"]
  """
  def lrange(list_name, start, stop) do
    GenServer.call(@name, {:lrange, list_name, start, stop})
  end

  @doc """
  Trims a list to the specified range.

  ## Parameters
    - `list_name` (binary): The name of the list.
    - `start` (integer): The start index (inclusive).
    - `stop` (integer): The stop index (inclusive).

  ## Returns
    - `:ok` on success.

  ## Example Usage

      iex> Remixdb.List.ltrim("mylist", 0, 1)
      :ok
  """
  def ltrim(list_name, start, stop) do
    GenServer.call(@name, {:ltrim, list_name, start, stop})
  end

  @doc """
  Sets the value at a specific index in a list.

  ## Parameters
    - `list_name` (binary): The name of the list.
    - `idx` (integer): The index to set.
    - `val` (any): The value to set.

  ## Returns
    - `:ok` on success.
    - `{:error, "ERR index out of range"}` if the index is invalid.

  ## Example Usage

      iex> Remixdb.List.lset("mylist", 1, "new_value")
      :ok
  """
  def lset(list_name, idx, val) when is_integer(idx) do
    GenServer.call(@name, {:lset, list_name, idx, val})
  end

  @doc """
  Gets the value at a specific index in a list.

  ## Parameters
    - `list_name` (binary): The name of the list.
    - `idx` (integer): The index to retrieve.

  ## Returns
    - The value at the specified index, or `nil` if the index is invalid.

  ## Example Usage

      iex> Remixdb.List.lindex("mylist", 1)
      "b"
  """
  def lindex(list_name, idx) when is_integer(idx) do
    GenServer.call(@name, {:lindex, list_name, idx})
  end

  def lindex(list_name, idx) do
    {idx, ""} = Integer.parse(idx)
    lindex(list_name, idx)
  end

  @doc """
  Appends one or more elements to the right of a list.

  ## Parameters
    - `list_name` (binary): The name of the list.
    - `items` (list): The elements to append.

  ## Returns
    - The new length of the list.

  ## Example Usage

      iex> Remixdb.List.rpush("mylist", ["d", "e"])
      5
  """
  def rpush(list_name, items) do
    GenServer.call(@name, {:rpush, list_name, items})
  end

  @doc """
  Appends one or more elements to the right of a list if the list exists.

  ## Parameters
    - `list_name` (binary): The name of the list.
    - `items` (list): The elements to append.

  ## Returns
    - The new length of the list, or `0` if the list does not exist.

  ## Example Usage

      iex> Remixdb.List.rpushx("mylist", ["f"])
      6
  """
  def rpushx(list_name, items) do
    GenServer.call(@name, {:rpushx, list_name, items})
  end

  @doc """
  Prepend one or more elements to the left of a list.

  ## Parameters
    - `list_name` (binary): The name of the list.
    - `items` (list): The elements to prepend.

  ## Returns
    - The new length of the list.

  ## Example Usage

      iex> Remixdb.List.lpush("mylist", ["x", "y"])
      5
  """
  def lpush(list_name, items) do
    GenServer.call(@name, {:lpush, list_name, items})
  end

  @doc """
  Appends one or more elements to the left of a list if the list exists.

  ## Parameters
    - `list_name` (binary): The name of the list.
    - `items` (list): The elements to append.

  ## Returns
    - The new length of the list, or `0` if the list does not exist.

  ## Example Usage

      iex> Remixdb.List.lpushx("mylist", ["f"])
      6
  """
  def lpushx(list_name, items) do
    GenServer.call(@name, {:lpushx, list_name, items})
  end

  @doc """
  Removes and returns the first element of a list.

  ## Parameters
    - `list_name` (binary): The name of the list.

  ## Returns
    - The first element of the list, or `nil` if the list is empty.

  ## Example Usage

      iex> Remixdb.List.lpop("mylist")
      "a"
  """
  def lpop(list_name) do
    GenServer.call(@name, {:lpop, list_name})
  end

  @doc """
  Removes and returns the last element of a list.

  ## Parameters
  - `list_name` (binary): The name of the list.

  ## Returns
  - The last element of the list, or `nil` if the list is empty.

  ## Example Usage

      iex> Remixdb.List.rpop("mylist")
      "c"
  """
  def rpop(list_name) do
    GenServer.call(@name, {:rpop, list_name})
  end

  @doc """
  Removes the last element of one list and prepends it to another.

  ## Parameters
    - `src` (binary): The source list.
    - `dest` (binary): The destination list.

  ## Returns
    - The value moved, or `nil` if the source list is empty.

  ## Example Usage

      iex> Remixdb.List.rpoplpush("mylist", "anotherlist")
      "c"
  """
  def rpoplpush(src, dest) do
    GenServer.call(@name, {:rpoplpush, src, dest})
  end

  @doc """
  Renames an existing list to a new name.

  ## Parameters
    - `old_name` (binary): The current name of the list.
    - `new_name` (binary): The new name for the list.

  ## Returns
    - `true` if the rename was successful.
    - `false` if the old name does not exist.

  ## Example Usage

      iex> Remixdb.List.rename("mylist", "newlist")
      true
  """
  def rename(old_name, new_name) do
    GenServer.call(@name, {:rename, old_name, new_name})
  end

  def handle_call({:rename, old_name, new_name}, _from, state) do
    {res, new_state} = Remixdb.Renamer.rename(state, old_name, new_name)
    {:reply, res, new_state}
  end

  def handle_call({:rpoplpush, src, dest}, _from, state) do
    src_list = state |> Map.get(src, [])
    dest_list = state |> Map.get(dest, [])
    {val, new_src, new_dest} = rpoplpush_helper(src_list, dest_list)
    new_state = state |> Map.put(src, new_src) |> Map.put(dest, new_dest)
    {:reply, val, new_state}
  end

  def handle_call(:flushall, _from, _state) do
    {:reply, :ok, Map.new()}
  end

  def handle_call(:dbsize, _from, state) do
    sz = state |> Map.keys() |> Enum.count()
    {:reply, sz, Map.new()}
  end

  def handle_call({:lset, list_name, idx, val}, _from, state) do
    res =
      Map.get(state, list_name, [])
      |> update_at(idx, val)

    case res do
      {:error, _} ->
        {:reply, {:error, "ERR index out of range"}, state}

      {:ok, ll} ->
        {:reply, :ok, update_state(ll, list_name, state)}
    end
  end

  def handle_call({:lindex, list_name, idx}, _from, state) do
    item =
      Map.get(state, list_name)
      |> Enum.at(idx)

    {:reply, item, state}
  end

  def handle_call({:ltrim, list_name, start, stop}, from, state)
      when is_integer(start) and is_integer(stop) do
    GenServer.reply(from, :ok)

    updated_list =
      Map.get(state, list_name, [])
      |> get_items_in_range(start, stop)

    {:noreply, Map.put(state, list_name, updated_list)}
  end

  def handle_call({:lrange, list_name, start, stop}, _from, state)
      when is_integer(start) and is_integer(stop) do
    res =
      Map.get(state, list_name, [])
      |> get_items_in_range(start, stop)

    {:reply, res, state}
  end

  def handle_call({:llen, list_name}, _from, state) do
    sz = Map.get(state, list_name, []) |> Enum.count()
    {:reply, sz, state}
  end

  def handle_call({:lpushx, list_name, new_items}, _from, state) do
    new_list =
      Map.get(state, list_name, [])
      |> concat_items_x(new_items, :left)

    sz = new_list |> Enum.count()
    {:reply, sz, update_state(new_list, list_name, state)}
  end

  def handle_call({:lpush, list_name, new_items}, _from, state) do
    new_list =
      Map.get(state, list_name, [])
      |> concat_items(new_items, :left)

    sz = new_list |> Enum.count()
    {:reply, sz, update_state(new_list, list_name, state)}
  end

  def handle_call({:rpushx, list_name, new_items}, _from, state) do
    new_list =
      Map.get(state, list_name, [])
      |> concat_items_x(new_items, :right)

    sz = new_list |> Enum.count()
    {:reply, sz, Map.put(state, list_name, new_list)}
  end

  def handle_call({:rpush, list_name, new_items}, _from, state) do
    new_list =
      Map.get(state, list_name, [])
      |> concat_items(new_items, :right)

    sz = new_list |> Enum.count()
    {:reply, sz, Map.put(state, list_name, new_list)}
  end

  def handle_call({:lpop, list_name}, _from, state) do
    {val, new_list} = pop_items_from_list(:left, list_name, state)
    new_state = update_state(new_list, list_name, state)
    {:reply, val, new_state}
  end

  def handle_call({:rpop, list_name}, _from, state) do
    {val, new_list} = pop_items_from_list(:right, list_name, state)
    new_state = update_state(new_list, list_name, state)
    {:reply, val, new_state}
  end

  defp concat_items_x([], _items, _direction) do
    []
  end

  defp concat_items_x(list, items, direction) do
    concat_items(list, items, direction)
  end

  defp concat_items(lst, items, :left = _direction) do
    items ++ lst
  end

  defp concat_items(lst, items, :right = _direction) do
    lst ++ items
  end

  defp pop_items_from_list(:left, list_name, state) do
    list = Map.get(state, list_name, [])
    {List.first(list), Enum.drop(list, 1)}
  end

  defp pop_items_from_list(:right, list_name, state) do
    list = Map.get(state, list_name, [])
    {List.last(list), Enum.drop(list, -1)}
  end

  defp get_items_in_range([], _start, _stop) do
    []
  end

  defp get_items_in_range(list, start, stop) when start < 0 do
    get_items_in_range(list, 0, stop)
  end

  defp get_items_in_range(list, start, stop) when stop < 0 do
    sz = Enum.count(list)
    last = sz + stop
    get_items_in_range(list, start, last)
  end

  defp get_items_in_range(list, start, stop) do
    list |> Enum.slice(start, stop + 1)
  end

  defp update_state([] = _list, list_name, state) do
    Map.delete(state, list_name)
  end

  defp update_state(list, list_name, state) do
    Map.put(state, list_name, list)
  end

  defp update_at(list, idx, val) do
    case idx < Enum.count(list) do
      false ->
        {:error, list}

      _ ->
        ll = list |> List.update_at(idx, fn _x -> val end)
        {:ok, ll}
    end
  end

  defp rpoplpush_helper(src = [], dest) do
    {nil, src, dest}
  end

  defp rpoplpush_helper(src, dest) do
    item = List.last(src)
    {item, Enum.drop(src, -1), [item | dest]}
  end
end
