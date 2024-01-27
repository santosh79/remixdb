alias Remixdb.Counter, as: Counter

defmodule Remixdb.String do
  use GenServer

  @name :remixdb_string

  def start_link(_args) do
    GenServer.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    rr = :erlang.make_ref() |> :erlang.ref_to_list() |> :erlang.list_to_binary()

    table_name = "remixdb_string::#{rr}" |> String.to_atom()
    table = :ets.new(table_name, [:named_table, :set, :public])
    {:ok, table}
  end

  def flushall(pid \\ @name) do
    GenServer.call(pid, :flushall)
  end

  def dbsize(pid \\ @name) do
    GenServer.call(pid, :dbsize)
  end

  def set(key, val, pid \\ @name) do
    GenServer.call(pid, {:set, key, val})
  end

  def getset(key, val, pid \\ @name) do
    GenServer.call(pid, {:getset, key, val})
  end

  def get(key, pid \\ @name) do
    GenServer.call(pid, {:get, key})
  end

  def rename(old_name, new_name, pid \\ @name) do
    GenServer.call(pid, {:rename, old_name, new_name})
  end

  def append(key, val, pid \\ @name) do
    GenServer.call(pid, {:append, key, val})
  end

  def incr(key, pid \\ @name) do
    GenServer.call(pid, {:incrby, key, 1})
  end

  def incrby(key, vv, pid \\ @name) do
    {val, ""} = Integer.parse(vv)
    GenServer.call(pid, {:incrby, key, val})
  end

  def decr(key, pid \\ @name) do
    GenServer.call(pid, {:incrby, key, -1})
  end

  def decrby(key, vv, pid \\ @name) do
    {val, ""} = Integer.parse(vv)
    GenServer.call(pid, {:incrby, key, val * -1})
  end

  def delete(key, pid \\ @name) do
    GenServer.call(pid, {:delete, key})
  end

  def handle_call({:delete, key}, _from, table) do
    true = :ets.delete(table, key)
    {:reply, :ok, table}
  end

  def handle_call(:flushall, _from, table) do
    table_name = :ets.info(table, :name)
    :ets.delete(table)
    new_table = :ets.new(table_name, [:named_table, :set, :public])
    {:reply, :ok, new_table}
  end

  def handle_call(:dbsize, _from, table) do
    size = :ets.info(table, :size)
    {:reply, size, table}
  end

  def handle_call({:append, key, val}, _from, table) do
    old_val = get_val(table, key)

    new_val =
      if old_val == nil do
        val
      else
        <<old_val::binary, val::binary>>
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
