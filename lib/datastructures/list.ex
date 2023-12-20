defmodule Remixdb.List do
  use GenServer

  @name :remixdb_list

  def start_link(_args) do
    GenServer.start_link(__MODULE__, :ok, name: @name)
  end

  def init(:ok) do
    {:ok, Map.new()}
  end

  def flushall() do
    GenServer.call(@name, :flushall)
  end

  def dbsize() do
    GenServer.call(@name, :dbsize)
  end

  def llen(list_name) do
    GenServer.call(@name, {:llen, list_name})
  end

  def lrange(list_name, start, stop) do
    GenServer.call(@name, {:lrange, list_name, start, stop})
  end

  def ltrim(list_name, start, stop) do
    GenServer.call(@name, {:ltrim, list_name, start, stop})
  end

  def lset(list_name, idx, val) when is_integer(idx) do
    GenServer.call(@name, {:lset, list_name, idx, val})
  end

  def lindex(list_name, idx) when is_integer(idx) do
    GenServer.call(@name, {:lindex, list_name, idx})
  end

  def lindex(list_name, idx) do
    {idx, ""} = Integer.parse(idx)
    lindex(list_name, idx)
  end

  def rpush(list_name, items) do
    GenServer.call(@name, {:rpush, list_name, items})
  end

  def rpushx(list_name, items) do
    GenServer.call(@name, {:rpushx, list_name, items})
  end

  def lpush(list_name, items) do
    GenServer.call(@name, {:lpush, list_name, items})
  end

  def lpushx(list_name, items) do
    GenServer.call(@name, {:lpushx, list_name, items})
  end

  def lpop(list_name) do
    GenServer.call(@name, {:lpop, list_name})
  end

  def rpop(list_name) do
    GenServer.call(@name, {:rpop, list_name})
  end

  def rpoplpush(src, dest) do
    GenServer.call(@name, {:rpoplpush, src, dest})
  end

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
