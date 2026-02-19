defmodule Remixdb.Set do
  @moduledoc """
  A Redis-like set store implemented with GenServer and ETS.
  ... (same as original)
  """
  use GenServer

  alias Remixdb.ETSHelpers, as: ETSHelpers

  @name :remixdb_set

  def start_link(_args) do
    GenServer.start_link(__MODULE__, :ok, name: @name)
  end

  def init(:ok) do
    table = :ets.new(@name, [:set, :private, {:write_concurrency, :auto}])
    {:ok, table}
  end

  def flushall(), do: GenServer.call(@name, :flushall)
  def dbsize(), do: GenServer.call(@name, :dbsize)
  def sadd(name, items), do: GenServer.call(@name, {:sadd, name, MapSet.new(items)})
  def scard(name), do: GenServer.call(@name, {:scard, name})
  def smembers(name), do: GenServer.call(@name, {:smembers, name})
  def sismember(name, val), do: GenServer.call(@name, {:sismember, name, val})
  def smismember(name, keys), do: GenServer.call(@name, {:smismember, name, keys})
  def sunion(keys), do: GenServer.call(@name, {:sunion, keys})
  def sinter(keys), do: GenServer.call(@name, {:sinter, keys})
  def sdiff(keys), do: GenServer.call(@name, {:sdiff, keys})
  def srandmember(set_name), do: GenServer.call(@name, {:srandmember, set_name})
  def smove(src, dest, member), do: GenServer.call(@name, {:smove, src, dest, member})
  def exists?(set_name), do: GenServer.call(@name, {:exists, set_name})
  def srem(name, items), do: GenServer.call(@name, {:srem, name, MapSet.new(items)})
  def spop(set_name), do: GenServer.call(@name, {:spop, set_name})
  def sunionstore(keys), do: GenServer.call(@name, {:sunionstore, keys})
  def sinterstore(keys), do: GenServer.call(@name, {:sinterstore, keys})
  def sdiffstore(keys), do: GenServer.call(@name, {:sdiffstore, keys})
  def rename(old_name, new_name), do: GenServer.call(@name, {:rename, old_name, new_name})

  # --- handle_call implementations ---

  def handle_call(:flushall, _from, table) do
    :ets.delete(table)
    new_table = :ets.new(@name, [:set, :private, {:write_concurrency, :auto}])
    {:reply, :ok, new_table}
  end

  def handle_call(:dbsize, _from, table) do
    {:reply, :ets.info(table, :size), table}
  end

  def handle_call({:smembers, name}, _from, table) do
    {:reply, get_set(table, name) |> Enum.into([]), table}
  end

  def handle_call({:sadd, name, new_items}, _from, table) do
    old_set = get_set(table, name)
    new_set = MapSet.union(old_set, new_items)
    put_set(table, name, new_set)
    {:reply, MapSet.size(new_set) - MapSet.size(old_set), table}
  end

  def handle_call({:sunion, set_names}, _from, table) when is_list(set_names) do
    res = get_sets(set_names, table) |> union() |> Enum.into([])
    {:reply, res, table}
  end

  def handle_call({:sinter, set_names}, _from, table) when is_list(set_names) do
    sets = get_sets(set_names, table)
    res =
      sets
      |> Enum.drop(1)
      |> Enum.reduce(List.first(sets), &MapSet.intersection/2)
      |> Enum.into([])
    {:reply, res, table}
  end

  def handle_call({:sdiff, set_names}, _from, table) when is_list(set_names) do
    {:reply, do_sdiff(set_names, table), table}
  end

  def handle_call({:scard, name}, _from, table) do
    {:reply, get_set(table, name) |> MapSet.size(), table}
  end

  def handle_call({:sismember, name, val}, _from, table) do
    {:reply, get_set(table, name) |> is_member?(val), table}
  end

  def handle_call({:smismember, name, keys}, _from, table) do
    set = get_set(table, name)
    {:reply, Enum.map(keys, &is_member?(set, &1)), table}
  end

  def handle_call({:srandmember, set_name}, _from, table) do
    rand_item = ETSHelpers.get_val(table, set_name) |> get_rand_item()
    {:reply, rand_item, table}
  end

  def handle_call({:smove, src, dest, member}, _from, table) do
    {upd_src, upd_dest, moved} = smove_helper(get_set(table, src), member, get_set(table, dest))
    put_set(table, src, upd_src)
    put_set(table, dest, upd_dest)
    {:reply, moved, table}
  end

  def handle_call({:exists, set_name}, _from, table) do
    {:reply, ETSHelpers.exists?(table, set_name), table}
  end

  def handle_call({:srem, name, items_to_remove}, _from, table) do
    old_set = get_set(table, name)
    new_set = MapSet.difference(old_set, items_to_remove)
    put_set(table, name, new_set)
    {:reply, MapSet.size(old_set) - MapSet.size(new_set), table}
  end

  def handle_call({:spop, set_name}, _from, table) do
    items = ETSHelpers.get_val(table, set_name)
    case get_rand_item(items) do
      nil ->
        {:reply, nil, table}
      rand_item ->
        put_set(table, set_name, MapSet.delete(items, rand_item))
        {:reply, rand_item, table}
    end
  end

  def handle_call({:sunionstore, keys}, _from, table) do
    res = get_sets(keys, table) |> union()
    put_set(table, List.first(keys), res)
    {:reply, MapSet.size(res), table}
  end

  def handle_call({:sinterstore, keys}, _from, table) do
    [first_key | rest_keys] = keys
    sets = get_sets(rest_keys, table)
    res = sets |> Enum.drop(1) |> Enum.reduce(List.first(sets), &MapSet.intersection/2)
    put_set(table, first_key, res)
    {:reply, MapSet.size(res), table}
  end

  def handle_call({:sdiffstore, keys}, _from, table) do
    [first_key | rest_keys] = keys
    res_list = do_sdiff(rest_keys, table)
    put_set(table, first_key, MapSet.new(res_list))
    {:reply, length(res_list), table}
  end

  def handle_call({:rename, old_name, new_name}, _from, table) do
    {:reply, ETSHelpers.rename(table, old_name, new_name), table}
  end

  # --- Private helpers ---

  defp get_set(table, name) do
    ETSHelpers.get_val(table, name) || MapSet.new()
  end

  defp put_set(table, name, set) do
    ETSHelpers.put_val(table, name, set)
  end

  defp get_sets(set_names, table) when is_list(set_names) do
    Enum.map(set_names, &get_set(table, &1))
  end

  defp union(sets) when is_list(sets) do
    Enum.reduce(sets, MapSet.new(), &MapSet.union/2)
  end

  defp get_rand_item(nil), do: nil
  defp get_rand_item(st) do
    if Enum.empty?(st), do: nil, else: Enum.random(st)
  end

  defp do_sdiff(set_names, table) do
    sets = get_sets(set_names, table)
    rest_union = sets |> Enum.drop(1) |> union()
    MapSet.difference(List.first(sets), rest_union) |> Enum.into([])
  end

  defp is_member?(set, key) do
    if MapSet.member?(set, key), do: 1, else: 0
  end

  defp smove_helper(src_set, member, dest_set) do
    case MapSet.member?(src_set, member) do
      false -> {src_set, dest_set, 0}
      _ ->
        { MapSet.delete(src_set, member), MapSet.put(dest_set, member), 1 }
    end
  end
end
