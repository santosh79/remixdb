defmdefmodule Remixdb.List do
  use GenServer

  @name :remixdb_list

  def start_link(_args) do
    GenServer.start_link(__MODULE__, :ok, name: @name)
  end

  def init(:ok) do
    table = :ets.new(@name, [:set, :private, {:write_concurrency, :auto}])
    {:ok, table}
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


  # Example implementation adjustments for ETS

  def handle_call(:flushall, _from, table) do
    :ets.delete(table)
    new_table = :ets.new(@name, [:named_table, :set, :public])
    {:reply, :ok, new_table}
  end

  def handle_call(:dbsize, _from, table) do
    size = :ets.info(table, :size)
    {:reply, size, table}
  end

  def handle_call({:llen, list_name}, _from, table) do
    size =
      :ets.lookup(table, list_name)
      |> case do
           [] -> 0
           [{_, list}] -> length(list)
         end

    {:reply, size, table}
  end

  # This is a simplified example for :lpush operation
  def handle_call({:lpush, list_name, items}, _from, table) do
    current_list =
      case :ets.lookup(table, list_name) do
        [] -> []
        [{_, list}] -> list
      end

    new_list = items ++ current_list
    true = :ets.insert(table, {list_name, new_list})
    {:reply, length(new_list), table}
  end

  def handle_call({:rpush, list_name, items}, _from, table) do
    current_list =
      case :ets.lookup(table, list_name) do
        [] -> []
        [{_, list}] -> list
      end

    new_list = current_list ++ items
    true = :ets.insert(table, {list_name, new_list})
    {:reply, length(new_list), table}
  end

  def handle_call({:lrange, list_name, start, stop}, _from, table)
  when is_integer(start) and is_integer(stop) do
    list =
      case :ets.lookup(table, list_name) do
        [] -> []
        [{_, val}] -> val
      end

    range = get_items_in_range(list, start, stop)

    {:reply, range, table}
  end

  def handle_call({:rpoplpush, src, dest}, _from, table) do
    src_list =
      case :ets.lookup(table, src) do
        [] -> []
        [{_, list}] -> list
      end

    dest_list =
      case :ets.lookup(table, dest) do
        [] -> []
        [{_, list}] -> list
      end

    case src_list do
      [] ->
        {:reply, nil, table}

      _ ->
        {popped, new_src} = List.pop_at(src_list, -1)
        new_dest = [popped | dest_list]

        true = :ets.insert(table, {src, new_src})
        true = :ets.insert(table, {dest, new_dest})

        {:reply, popped, table}
    end
  end

  def handle_call({:ltrim, list_name, start, stop}, from, table)
  when is_integer(start) and is_integer(stop) do
    current_list =
      case :ets.lookup(table, list_name) do
        [] -> []
        [{_, list}] -> list
      end

    trimmed =
      get_items_in_range(current_list, start, stop)

    :ets.insert(table, {list_name, trimmed})
    GenServer.reply(from, :ok)

    {:noreply, table}
  end

  def handle_call({:rename, old_name, new_name}, _from, table) do
    case :ets.lookup(table, old_name) do
      [] ->
        # Old list does not exist
        {:reply, false, table}

      [{^old_name, list}] ->
        # Insert under the new name and delete the old one
        true = :ets.insert(table, {new_name, list})
        true = :ets.delete(table, old_name)
        {:reply, true, table}
    end
  end

  def handle_call({:rpop, list_name}, _from, table) do
    case :ets.lookup(table, list_name) do
      [] ->
        # List doesn't exist, return nil
        {:reply, nil, table}

      [{^list_name, list}] ->
        case Enum.reverse(list) do
          [] ->
            # List is empty
            {:reply, nil, table}

          [last | rest_reversed] ->
            new_list = Enum.reverse(rest_reversed)
            :ets.insert(table, {list_name, new_list})
            {:reply, last, table}
        end
    end
  end

  def handle_call({:lindex, list_name, idx}, _from, table) when is_integer(idx) do
    case :ets.lookup(table, list_name) do
      [] ->
        {:reply, nil, table}

      [{^list_name, list}] ->
        adjusted_idx =
        if idx < 0 do
          length(list) + idx
        else
          idx
        end

        value = Enum.at(list, adjusted_idx)
        {:reply, value, table}
    end
  end

  def handle_call({:lpop, list_name}, _from, table) do
    case :ets.lookup(table, list_name) do
      [] ->
        {:reply, nil, table}

      [{^list_name, [head | tail]}] ->
        :ets.insert(table, {list_name, tail})
        {:reply, head, table}

      [{^list_name, []}] ->
        {:reply, nil, table}
    end
  end

  def handle_call({:rpushx, list_name, items}, _from, table) do
    case :ets.lookup(table, list_name) do
      [] ->
        {:reply, 0, table}

      [{^list_name, list}] ->
        new_list = list ++ items
        true = :ets.insert(table, {list_name, new_list})
        {:reply, length(new_list), table}
    end
  end

  def handle_call({:lset, list_name, idx, val}, _from, table) when is_integer(idx) do
    case :ets.lookup(table, list_name) do
      [] ->
        {:reply, {:error, "ERR index out of range"}, table}

      [{^list_name, list}] ->
        list_len = length(list)

        # Handle negative indices
        index = if idx < 0, do: list_len + idx, else: idx

        if index < 0 or index >= list_len do
          {:reply, {:error, "ERR index out of range"}, table}
        else
          updated_list = List.replace_at(list, index, val)
          true = :ets.insert(table, {list_name, updated_list})
          {:reply, :ok, table}
        end
    end
  end

  # Implement other operations similarly, using ETS functions for state management

  # Helper function adjustments for ETS...
  defp get_items_in_range(list, start, stop) do
    len = length(list)

    norm_start = 
      cond do
      start < 0 -> max(len + start, 0)
      true -> min(start, len)
    end

    norm_stop = 
      cond do
      stop < 0 -> max(len + stop, 0)
      true -> min(stop, len - 1)
    end

    if norm_start > norm_stop do
      []
    else
      Enum.slice(list, norm_start, norm_stop - norm_start + 1)
    end
  end
end
