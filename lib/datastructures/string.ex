alias Remixdb.Counter, as: Counter

defmodule Remixdb.String do
  @moduledoc """
  A Redis-like string store implemented with GenServer and ETS.

  This module allows storing, retrieving, appending, and manipulating string data,
  similar to Redis string commands. It also supports operations like key renaming
  and atomic increments/decrements.

  ## Features

  - Set and get string values by keys.
  - Append to existing values.
  - Increment or decrement numeric values stored as strings.
  - Atomically retrieve and set values.
  - Rename keys and flush all data.

  ## Example Usage

      iex> Remixdb.String.set("key", "value")
      :ok

      iex> Remixdb.String.get("key")
      "value"

      iex> Remixdb.String.append("key", "123")
      8

      iex> Remixdb.String.get("key")
      "value123"

      iex> Remixdb.String.incr("counter")
      1

      iex> Remixdb.String.dbsize()
      2
  """

  use GenServer

  @name :remixdb_string

  @doc """
  Starts the `Remixdb.String` GenServer.

  ## Parameters
    - `_args` (any): Arguments to initialize the GenServer (currently ignored).

  ## Returns
    - `{:ok, pid}` on success.

  ## Example

      Remixdb.String.start_link(:ok)
  """
  def start_link(_args) do
    GenServer.start_link(__MODULE__, :ok, name: @name)
  end

  def init(:ok) do
    table = :ets.new(@name, [:set, :private, {:write_concurrency, :auto}])
    {:ok, table}
  end

  @doc """
  Flushes all keys and values in the store.

  ## Returns
    - `:ok` on success.

  ## Example

      Remixdb.String.flushall()
      :ok
  """
  def flushall() do
    GenServer.call(@name, :flushall)
  end

  @doc """
  Gets the total number of keys in the store.

  ## Returns
    - The size of the database as an integer.

  ## Example

      Remixdb.String.dbsize()
      2
  """
  def dbsize() do
    GenServer.call(@name, :dbsize)
  end

  def exists?(key) do
    GenServer.call(@name, {:exists, key})
  end

  @doc """
  Sets a string value for a key.

  ## Parameters
  - `key` (any): The key to set.
  - `val` (any): The value to store.

  ## Returns
  - `:ok` on success.

  ## Example

      Remixdb.String.set("foo", "bar")
      :ok
  """
  def set(key, val) do
    GenServer.call(@name, {:set, key, val})
  end

  @doc """
  Atomically gets the current value of a key and sets it to a new value.

  ## Parameters
    - `key` (any): The key to retrieve and update.
    - `val` (any): The new value to set.

  ## Returns
    - The previous value, or `nil` if the key does not exist.

  ## Example

      Remixdb.String.getset("foo", "baz")
      "bar"
  """
  def getset(key, val) do
    GenServer.call(@name, {:getset, key, val})
  end

  @doc """
  Gets the value of a key.

  ## Parameters
  - `key` (any): The key to retrieve.

  ## Returns
  - The value of the key, or `nil` if the key does not exist.

  ## Example

  Remixdb.String.get("foo")
  "baz"
  """
  def get(key) do
    GenServer.call(@name, {:get, key})
  end

  @doc """
  Renames a key to a new name **only if the new name does not already exist**.

  This behaves like `rename/2`, but does nothing if the `new_name` key already exists.
  It returns `"1"` if the rename was successful, and `"0"` if the destination key already exists.
  If the source key does not exist, it returns an error tuple.

  ## Parameters

    - `old_name` (any): The current key name.
    - `new_name` (any): The new key name.

  ## Returns

    - `"1"` if the rename was successful.
    - `"0"` if the destination key already exists.
    - `{:error, "ERR no such key"}` if the source key does not exist.

  ## Examples

    iex> Remixdb.String.renamenx("foo", "bar")
    "1"

    iex> Remixdb.String.renamenx("foo", "baz") # when "baz" already exists
    "0"

    iex> Remixdb.String.renamenx("unknown", "anything")
    {:error, "ERR no such key"}
  """
  def renamenx(old_name, new_name) do
    GenServer.call(@name, {:renamenx, old_name, new_name})
  end

  @doc """
  Renames a key to a new name.

  ## Parameters
    - `old_name` (any): The current key name.
    - `new_name` (any): The new key name.

  ## Returns
    - `true` if the key was renamed successfully.
    - `false` if the old key does not exist.

  ## Example

      Remixdb.String.rename("foo", "bar")
      true
  """
  def rename(old_name, new_name) do
    GenServer.call(@name, {:rename, old_name, new_name})
  end

  @doc """
  Appends a value to an existing key.

  ## Parameters
    - `key` (any): The key whose value will be appended to.
    - `val` (any): The value to append.

  ## Returns
    - The length of the string after appending.

  ## Example

      Remixdb.String.append("key", "123")
      8
  """
  def append(key, val) do
    GenServer.call(@name, {:append, key, val})
  end

  @doc """
  Increments the numeric value of a key by 1.

  ## Parameters
    - `key` (any): The key to increment.

  ## Returns
    - The new value of the key as an integer.

  ## Example

      Remixdb.String.incr("counter")
      1
  """
  def incr(key) do
    GenServer.call(@name, {:incrby, key, 1})
  end

  @doc """
  Increments the numeric value of a key by a specified amount.

  ## Parameters
    - `key` (any): The key to increment.
    - `vv` (string): The value to increment by.

  ## Returns
    - The new value of the key as an integer.

  ## Example

      Remixdb.String.incrby("counter", "10")
      11
  """
  def incrby(key, vv) do
    {val, ""} = Integer.parse(vv)
    GenServer.call(@name, {:incrby, key, val})
  end

  @doc """
  Decrements the numeric value of a key by 1.

  ## Parameters
    - `key` (any): The key to decrement.

  ## Returns
    - The new value of the key as an integer.

  ## Example

      Remixdb.String.decr("counter")
      10
  """
  def decr(key) do
    GenServer.call(@name, {:incrby, key, -1})
  end

  @doc """
  Decrements the numeric value of a key by a specified amount.

  ## Parameters
    - `key` (any): The key to decrement.
    - `vv` (string): The value to decrement by.

  ## Returns
    - The new value of the key as an integer.

  ## Example

      Remixdb.String.decrby("counter", "5")
      5
  """
  def decrby(key, vv) do
    {val, ""} = Integer.parse(vv)
    GenServer.call(@name, {:incrby, key, val * -1})
  end

  def handle_call(:flushall, _from, table) do
    :ets.delete(table)
    new_table = :ets.new(@name, [:named_table, :set, :public])
    {:reply, :ok, new_table}
  end

  def handle_call(:dbsize, _from, table) do
    size = :ets.info(table, :size)
    {:reply, size, table}
  end

  def handle_call({:append, key, val}, _from, table) do
    old_val = get_val(table, key)

    new_val =
      case old_val do
        nil -> val
        _ -> <<old_val::binary, val::binary>>
      end

    sz = new_val |> :erlang.byte_size()
    set_val(table, key, new_val)
    {:reply, sz, table}
  end

  def handle_call({:incrby, key, incrby}, _from, table) do
    new_val = Counter.incrby(get_val(table, key), incrby)
    set_val(table, key, new_val)
    {:reply, new_val, table}
  end

  def handle_call({:get, key}, _from, table) do
    val = get_val(table, key)
    {:reply, val, table}
  end

  def handle_call({:getset, key, val}, _from, table) do
    old_val = get_val(table, key)
    set_val(table, key, val)
    {:reply, old_val, table}
  end

  def handle_call({:set, key, val}, _from, table) do
    set_val(table, key, val)
    {:reply, :ok, table}
  end

  def handle_call({:renamenx, old_name, new_name}, _from, table) do
    case get_val(table, old_name) do
      nil ->
        response = {:error, "ERR no such key"}
        {:reply, response, table}
      _ ->
        case get_val(table, new_name) do
          nil ->
            private_rename(old_name, new_name, table)
            {:reply, "1", table}
          _ -> 
            {:reply, "0", table}
        end
    end
  end

  def handle_call({:rename, old_name, new_name}, _from, table) do
    result = private_rename(old_name, new_name, table)
    {:reply, result, table}
  end

  def handle_call({:exists, key}, _from, table) do
    case get_val(table, key) do
      nil -> false
      _ -> true
    end
  end

  defp private_rename(old_name, new_name, table) do
    old_value =
      case :ets.lookup(table, old_name) do
        [{^old_name, value}] -> value
        [] -> nil
      end

    case old_value do
      nil ->
        false

      _ ->
        true = :ets.insert(table, {new_name, old_value})
        true = :ets.delete(table, old_name)
        true
    end
  end
  

  defp get_val(table, key) do
    case :ets.lookup(table, key) do
      [{^key, value}] -> value
      [] -> nil
    end
  end

  defp set_val(table, key, val) do
    :ets.insert(table, {key, val})
  end
end
