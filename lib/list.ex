defmodule Remixdb.List do
  use GenServer
  def start(key_name) do
    GenServer.start_link __MODULE__, {:ok, key_name}, []
  end

  def init({:ok, key_name}) do
    {:ok, %{items: [], key_name: key_name}}
  end

  def rpush(name, items) do
    GenServer.call(name, {:rpush, items})
  end

  def rpushx(nil, _items) do; 0; end
  def rpushx(name, items) do
    GenServer.call(name, {:rpushx, items})
  end

  def lpush(name, items) do
    GenServer.call(name, {:lpush, items})
  end

  def lpushx(nil, _items) do; 0; end
  def lpushx(name, items) do
    GenServer.call(name, {:lpushx, items})
  end

  def lpop(nil) do; :undefined; end
  def lpop(name) do
    GenServer.call(name, :lpop)
  end

  def rpop(nil) do; :undefined; end
  def rpop(name) do
    GenServer.call(name, :rpop)
  end

  def rpoplpush(nil, _) do; :undefined; end
  def rpoplpush(src, dest) do
    GenServer.call(dest, {:rpoplpush, src})
  end

  def llen(nil) do; 0; end
  def llen(name) do
    GenServer.call(name, :llen)
  end

  def lrange(nil, _start, _stop) do; []; end
  def lrange(name, start, stop) do
    to_i = &String.to_integer/1
    GenServer.call(name, {:lrange, to_i.(start), to_i.(stop)})
  end

  def ltrim(nil, _start, _stop) do; []; end
  def ltrim(name, start, stop) do
    to_i = &String.to_integer/1
    GenServer.call(name, {:ltrim, to_i.(start), to_i.(stop)})
  end

  def lindex(nil, _idx) do; :undefined; end
  def lindex(name, idx) do
    GenServer.call(name, {:lindex, String.to_integer(idx)})
  end

  def lset(name, idx, val) do
    GenServer.call(name, {:lset, String.to_integer(idx), val})
  end

  def handle_info(_, state), do: {:noreply, state}

  def handle_call(:llen, _from, %{items: items} = state) do
    list_sz = items |> Enum.count
    {:reply, list_sz, state}
  end

  def handle_call({:rpush, new_items}, _from, state) do
    add_items_to_list :right, new_items, state
  end

  def handle_call({:rpushx, new_items}, _from, state) do
    add_items_to_list :right, new_items, state
  end

  def handle_call({:lpush, new_items}, _from, state) do
    add_items_to_list :left, new_items, state
  end

  def handle_call({:lpushx, new_items}, _from, state) do
    add_items_to_list :left, new_items, state
  end

  def handle_call(:lpop, _from, state) do
    pop_items_from_list :left, state
  end

  def handle_call(:rpop, _from, state) do
    pop_items_from_list :right, state
  end

  def handle_call({:rpoplpush, src}, _from, %{items: _items} = state) do
    item = Remixdb.List.rpop src
    {_, _, updated_state} = add_items_to_list :left, [item], state
    {:reply, item, updated_state}
  end

  def handle_call({:lrange, start, stop}, _from, %{items: items} = state) do
    items_in_range = get_items_in_range start, stop, items
    {:reply, items_in_range, state}
  end

  def handle_call({:ltrim, start, stop}, _from, %{items: items} = state) do
    items_in_range = get_items_in_range start, stop, items
    new_state = update_state state, items_in_range
    {:reply, :ok, new_state}
  end

  def handle_call({:lindex, idx}, _from, %{items: items} = state) do
    item = get_items_in_range(idx, -1, items) |> List.first
    {:reply, item, state}
  end

  def handle_call({:lset, idx, val}, _from, %{items: items} = state) do
    length      = items |> Enum.count
    invalid_idx = idx >= length
    case invalid_idx do
      true ->
        {:reply, {:error, "ERR index out of range"}, state}
      _ ->
        new_items       = items |> List.update_at(idx, fn(_x) -> val end)
        new_state = update_state state, new_items
        {:reply, :ok, new_state}
    end
  end

  # SantoshTODO: Mixin Termination stuff
  def terminate(:normal, %{key_name: key_name}) do
    Remixdb.KeyHandler.remove key_name
    :ok
  end

  defp get_items_in_range(start, stop, items) do
    length = items |> Enum.count
    take_amt = (case (stop >= 0) do
      true -> stop
      _    -> (length - :erlang.abs(stop))
    end) + 1
    drop_amt = case (start >= 0) do
      true -> start
      _    -> case (:erlang.abs(start) > length) do
        true -> 0
        _    -> (length - :erlang.abs(start))
      end
    end
    items |> Enum.take(take_amt) |> Enum.drop(drop_amt)
  end

  defp add_items_to_list(push_direction, new_items, state) do
    %{items: items} = state
    updated_items = case push_direction do
      :left  -> (new_items ++ items)
      :right -> (items ++ new_items)
    end
    new_state = update_state state, updated_items
    list_sz = updated_items |> Enum.count
    {:reply, list_sz, new_state}
  end

  defp pop_items_from_list(pop_direction, state) do
    {head, updated_items} = case Map.get(state, :items) do
      []    ->
        {:undefined, []}
      list ->
        case pop_direction do
          :left ->
            [h|t] = list
            {h, t}
          :right ->
            [h|t] = list |> :lists.reverse
            {h, (t |> :lists.reverse)}
        end
    end
    Remixdb.Keys.popped_out? updated_items, self
    new_state = update_state state, updated_items
    {:reply, head, new_state}
  end

  defp update_state(state, updated_items) do
    Map.merge(state, %{items: updated_items})
  end
end
