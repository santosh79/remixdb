alias Remixdb.Counter, as: Counter

defmodule Remixdb.Hash do
  @moduledoc """
  A Redis-like hash store implemented with GenServer.

  This module allows you to store and manipulate hashes (key-value pairs within named hashes), similar to Redis' hash commands. It supports operations such as setting, getting, and incrementing fields, retrieving all keys or values, and checking the existence of fields.

  ## Features

  - Create and manipulate named hashes with fields.
  - Perform atomic operations like field increments and field setting.
  - Retrieve keys, values, and all data from hashes.
  - Rename hashes and flush all stored hashes.

  ## Example Usage

  iex> Remixdb.Hash.start_link(:ok)
  {:ok, pid}
  
  iex> Remixdb.Hash.hset("myhash", "field1", "value1")
  1
  
  iex> Remixdb.Hash.hget("myhash", "field1")
  "value1"
  
  iex> Remixdb.Hash.hkeys("myhash")
  ["field1"]
  
  iex> Remixdb.Hash.hvals("myhash")
  ["value1"]
  
  iex> Remixdb.Hash.hlen("myhash")
  1
  
  iex> Remixdb.Hash.flushall()
  :ok
  """
  use GenServer

  @name :remixdb_hash

  @doc """
  Starts the `Remixdb.Hash` GenServer.

  ## Parameters
  - `_args` (any): Arguments to initialize the GenServer (currently ignored).

  ## Returns
  - `{:ok, pid}` on success.

  ## Example Usage

  iex> Remixdb.Hash.start_link(:ok)
  :ok
  """
  def start_link(_args) do
    GenServer.start_link __MODULE__, :ok, name: @name
  end

  def init(:ok) do
    # Create a named ETS table with public access and good read/write concurrency options.
    table = :ets.new(@name, [:named_table, :public, read_concurrency: true, write_concurrency: true])
    {:ok, table}
  end

  # def init(:ok) do
  #   {:ok, Map.new}
  # end

  @doc """
  Flushes all hashes and their fields from the store.

  ## Returns
  - `:ok` on success.

  ## Example Usage

  iex> Remixdb.Hash.flushall()
  :ok
  """
  def flushall() do
    GenServer.call @name, :flushall
  end

  @doc """
  Gets the total number of hashes stored.

  ## Returns
  - The total number of stored hashes as an integer.

  ## Example

  Remixdb.Hash.dbsize()
  1
  """
  def dbsize() do
    GenServer.call @name, :dbsize
  end

  @doc """
  Sets the value of a field in a hash.

  ## Parameters
  - `hash_name` (binary): The name of the hash.
  - `key` (binary): The field to set.
  - `val` (any): The value to set.

  ## Returns
  - `1` if a new field was created.
  - `0` if an existing field was updated.

  ## Example Usage

  iex> Remixdb.Hash.hset("myhash", "field1", "value1")
  1
  """
  def hset(hash_name, key, val) do
    GenServer.call @name, {:hset, hash_name, key, val}
  end

  @doc """
  Sets the value of a field in a hash, only if the field does not already exist.

  ## Parameters
  - `hash_name` (binary): The name of the hash.
  - `key` (binary): The field to set.
  - `val` (any): The value to set.

  ## Returns
  - `1` if the field was set.
  - `0` if the field already exists.

  ## Example Usage

  iex> Remixdb.Hash.hsetnx("myhash", "field1", "value1")
  1

  iex> Remixdb.Hash.hget("myhash", "field1")
  "value1"

  iex> Remixdb.Hash.hsetnx("myhash", "field1", "new_value")
  0

  iex> Remixdb.Hash.hget("myhash", "field1")
  "value1"
  """
  def hsetnx(hash_name, key, val) do
    GenServer.call(@name, {:hsetnx, hash_name, key, val})
  end

  @doc """
  sets multiple fields in a hash at once.

  ## Parameters
  - `hash_name` (binary): the name of the hash.
  - `fields` (list): a flat list of key-value pairs to set.

  ## Returns
  - `"ok"` if the operation is successful.

  ## Example Usage

  iex> Remixdb.Hash.hmset("myhash", ["field1", "value1", "field2", "value2"])
  "ok"
  """
  def hmset(hash_name, fields) do
    GenServer.call @name, {:hmset, hash_name, fields}
  end

  @doc """
  Gets the values of multiple fields in a hash.

  ## Parameters
  - `hash_name` (binary): the name of the hash.
  - `fields` (list): a list of keys whose values are to be retrieved.

  ## Returns
  - a list of values corresponding to the requested fields. if a field does not exist, `nil` is returned in its place.

  ## Example Usage

  iex> Remixdb.Hash.hmget("myhash", ["field1", "field2", "field3"])
  ["value1", "value2", nil]
  """
  def hmget(hash_name, fields) do
    GenServer.call @name, {:hmget, hash_name, fields}
  end

  @doc """
  Gets the value of a field in a hash.

  ## Parameters
  - `hash_name` (binary): The name of the hash.
  - `key` (binary): The field to retrieve.

  ## Returns
  - The value of the field, or `nil` if the field does not exist.

  ## Example Usage

  iex> Remixdb.Hash.hget("myhash", "field1")
  "value1"
  """
  def hget(hash_name, key) do
    GenServer.call @name, {:hget, hash_name, key}
  end

  @doc """
  Gets the number of fields in a hash.

  ## Parameters
  - `hash_name` (binary): The name of the hash.

  ## Returns
  - The number of fields in the hash as an integer.

  ## Example Usage

  iex> Remixdb.Hash.hlen("myhash")
  2
  """
  def hlen(hash_name) do
    GenServer.call @name, {:hlen, hash_name}
  end

  @doc """
  Gets all fields and their values from a hash.

  ## Parameters
  - `hash_name` (binary): The name of the hash.

  ## Returns
  - A list of key-value pairs in the hash.

  ## Example Usage

  iex> Remixdb.Hash.hgetall("myhash")
  ["field1", "value1"]
  """
  def hgetall(hash_name) do
    GenServer.call @name, {:hgetall, hash_name}
  end

  @doc """
  Gets all the keys in a hash.

  ## Parameters
  - `hash_name` (binary): The name of the hash.

  ## Returns
  - A list of keys in the hash.

  ## Example Usage

  iex> Remixdb.Hash.hkeys("myhash")
  ["field1"]
  """
  def hkeys(hash_name) do
    GenServer.call @name, {:hkeys, hash_name}
  end

  @doc """
  Gets all the values in a hash.

  ## Parameters
  - `hash_name` (binary): The name of the hash.

  ## Returns
  - A list of values in the hash.

  ## Example Usage

  iex> Remixdb.Hash.hvals("myhash")
  ["value1"]
  """
  def hvals(hash_name) do
    GenServer.call @name, {:hvals, hash_name}
  end

  @doc """
  Checks if a field exists in a hash.

  ## Parameters
  - `hash_name` (binary): The name of the hash.
  - `key` (binary): The field to check.

  ## Returns
  - `1` if the field exists.
  - `0` if the field does not exist.

  ## Example Usage
  iex> Remixdb.Hash.hexists("myhash", "field1")
  1

  iex> Remixdb.Hash.hexists("myhash", "field3")
  0
  """
  def hexists(hash_name, key) do
    GenServer.call @name, {:hexists, hash_name, key}
  end

  @doc """
  Gets the string length of the value of a field in a hash.

  ## Parameters
  - `hash_name` (binary): The name of the hash.
  - `key` (binary): The field whose value's string length is to be retrieved.

  ## Returns
  - The length of the string value of the field as an integer.
  - `0` if the field does not exist.

  ## Example Usage
  iex> Remixdb.Hash.hset("myhash", "field1", "value1")
  1

  iex> Remixdb.Hash.hstrlen("myhash", "field1")
  6

  iex> Remixdb.Hash.hstrlen("myhash", "field2")
  0
  """
  def hstrlen(hash_name, key) do
    GenServer.call @name, {:hstrlen, hash_name, key}
  end

  @doc """
  Deletes one or more fields from a hash.

  ## Parameters
  - `hash_name` (binary): The name of the hash.
  - `keys` (list): The fields to delete.

  ## Returns
  - The number of fields deleted.

  ## Example Usage

  iex> Remixdb.Hash.hdel("myhash", ["field1"])
  1
  """
  def hdel(hash_name, keys) do
    GenServer.call @name, {:hdel, hash_name, keys}
  end

  @doc """
  Increments the numeric value of a field in a hash by the given amount.

  ## Parameters
  - `hash_name` (binary): The name of the hash.
  - `key` (binary): The field to increment.
  - `amt` (integer): The amount to increment by.

  ## Returns
  - The new value of the field.

  ## Example Usage

  iex> Remixdb.Hash.hincrby("myhash", "counter", 5)
  5
  """
  def hincrby(hash_name, key, amt) do
    GenServer.call @name, {:hincrby, hash_name, key, amt}
  end

  @doc """
  Renames a hash.

  ## Parameters
  - `old_name` (binary): The current name of the hash.
  - `new_name` (binary): The new name for the hash.

  ## Returns
  - `true` if the rename was successful.
  - `false` if the old name does not exist.

  ## Example Usage

  iex> Remixdb.Hash.rename("myhash", "newhash")
  true
  """
  def rename(old_name, new_name) do
    GenServer.call @name, {:rename, old_name, new_name}
  end

  def handle_call({:hincrby, hash_name, key, amt}, _from, table) do
    hash = get_hash(table, hash_name)

    new_val = Counter.incrby Map.get(hash, key), amt
    new_hash = Map.put(hash, key, new_val)

    true = put_hash(table, hash_name, new_hash)

    {:reply, new_val, table}
  end

  def handle_call({:hdel, hash_name, keys}, _from, table) do
    hash = get_hash(table, hash_name)

    num_deleted = Enum.count(keys, fn(kk) ->
      Map.has_key? hash, kk
    end)

    new_hash = Enum.reduce(keys, hash, fn(kk, acc) ->
      Map.delete(acc, kk)
    end)

    true = put_hash(table, hash_name, new_hash)

    {:reply, num_deleted, table}
  end

  def handle_call({:hstrlen, hash_name, key}, _from, table) do
    hash = get_hash(table, hash_name)
    res = hash
    |> Map.get(key, "")
    |> :erlang.byte_size

    {:reply, res, table}
  end

  def handle_call({:hkeys, hash_name}, _from, table) do
    hash = get_hash(table, hash_name)
    keys = hash |> Map.keys

    {:reply, keys, table}
  end

  def handle_call({:hvals, hash_name}, _from, table) do
    hash = get_hash(table, hash_name)
    vals = hash |> Map.values

    {:reply, vals, table}
  end

  def handle_call({:hget, hash_name, key_name}, _from, table) do
    hash = get_hash(table, hash_name)
    val = Map.get(hash, key_name)

    {:reply, val, table}
  end

  def handle_call({:hgetall, hash_name}, _from, table) do
    hash = get_hash(table, hash_name)
    vals = hash
    |> Enum.reduce([], fn({kk, vv}, acc) ->
      [kk|[vv|acc]]
    end)
    
    {:reply, vals, table}
  end

  def handle_call(:flushall, _from, table) do
    :ets.delete(table)
    new_table = :ets.new(@name, [:named_table, :public, read_concurrency: true, write_concurrency: true])
    {:reply, :ok, new_table}
  end

  def handle_call({:hmget, hash_name, fields}, _from, table) do
    map = get_hash(table, hash_name)

    res = fields
    |> Enum.map(fn(key) ->
      Map.get(map, key)
    end)

    {:reply, res, table}
  end

  def handle_call({:hmset, hash_name, fields}, _from, table) do
    old_hash = get_hash(table, hash_name)

    fields_map = fields
    |> Enum.chunk_every(2)
    |> Map.new(fn([k, v]) ->
      {k, v}
    end)

    new_hash = Map.merge(old_hash, fields_map)
    true = put_hash(table, hash_name, new_hash)
    {:reply, "OK", table}
  end

  def handle_call({:hsetnx, hash_name, key, val}, _from, table) do
    old_hash = get_hash(table, hash_name)
    case Map.has_key?(old_hash, key) do
      false ->
        new_hash = Map.put(old_hash, key, val)
        true = put_hash(table, hash_name, new_hash)
        {:reply, 1, table}
      _ ->
        {:reply, 0, table}
    end
  end

  def handle_call({:hset, hash_name, key, val}, _from, table) do
    old_hash =  get_hash(table, hash_name)
    new_hash = old_hash |> Map.put(key, val)
    true = put_hash(table, hash_name, new_hash)

    {:reply, key_inserted?(old_hash, key), table}
  end

  def handle_call(:dbsize, _from, table) do
    sz = :ets.info(table, :size)
    {:reply, sz, table}
  end

  def handle_call({:hlen, hash_name}, _from, table) do
    sz = get_hash(table, hash_name) |> Map.keys |> length()
    {:reply, sz, table}
  end

  def handle_call({:hexists, hash_name, key}, _from, table) do
    res = get_hash(table, hash_name) |> has_key?(key)
    {:reply, res, table}
  end

  def handle_call({:rename, old_name, new_name}, _from, table) do
    hash = get_hash(table, old_name)
    true = put_hash(table, new_name, hash)
    true = delete_hash(table, old_name)

    # If the hash did not exist in the first place return false/else true
    res = (hash !== %{})

    {:reply, res, table}
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

  defp get_hash(table, hash_name) do
    case :ets.lookup(table, hash_name) do
      [] -> %{}
      [{^hash_name, hash}] -> hash
    end
  end

  defp put_hash(table, hash_name, hash) do
    :ets.insert(table, {hash_name, hash})
  end

  defp delete_hash(table, hash_name) do
    :ets.delete(table, hash_name)
  end
end
