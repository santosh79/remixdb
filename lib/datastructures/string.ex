alias Remixdb.Counter, as: Counter

defmodule Remixdb.String do
  use GenServer

  @name :remixdb_string

  def start_link(_args) do
    GenServer.start_link(__MODULE__, :ok, name: @name)
  end

  def init(:ok) do
    table = :ets.new(@name, [:named_table, :set, :public])
    {:ok, table}
  end

  def flushall() do
    GenServer.call(@name, :flushall)
  end

  def dbsize() do
    GenServer.call(@name, :dbsize)
  end

  def set(key, val) do
    GenServer.call(@name, {:set, key, val})
  end

  def getset(key, val) do
    GenServer.call(@name, {:getset, key, val})
  end

  def get(key) do
    GenServer.call(@name, {:get, key})
  end

  def rename(old_name, new_name) do
    GenServer.call(@name, {:rename, old_name, new_name})
  end

  def append(key, val) do
    GenServer.call(@name, {:append, key, val})
  end

  def incr(key) do
    GenServer.call(@name, {:incrby, key, 1})
  end

  def incrby(key, vv) do
    {val, ""} = Integer.parse(vv)
    GenServer.call(@name, {:incrby, key, val})
  end

  def decr(key) do
    GenServer.call(@name, {:incrby, key, -1})
  end

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

  def handle_call({:rename, old_name, new_name}, _from, table) do
    old_value =
      case :ets.lookup(table, old_name) do
        [{^old_name, value}] -> value
        [] -> nil
      end

    result =
      case old_value do
        nil ->
          false

        _ ->
          :ets.insert(table, {new_name, old_value})
          :ets.delete(table, old_name)
          true
      end

    {:reply, result, table}
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
