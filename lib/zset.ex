defmodule Remixdb.ZSet do
  use GenServer
  def start(key_name) do
    GenServer.start_link __MODULE__, {:ok, key_name}, []
  end

  def init({:ok, key_name}) do
    {:ok, %{items: RemixDB.SortedSet.new(), key_name: key_name}}
  end

  def zadd(name, args) do
    GenServer.call name, {:zadd, args}
  end

  def zrem(nil, _args) do; 0; end
  def zrem(name, args) do
    GenServer.call name, {:zrem, args}
  end


  def zcard(name) do
    GenServer.call name, :zcard
  end

  def zrank(nil, _member) do; :undefined; end
  def zrank(name, member) do
    GenServer.call name, {:zrank, member}
  end

  def zscore(nil, _member) do; :undefined; end
  def zscore(name, member) do
    GenServer.call name, {:zscore, member}
  end

  def zcount(nil, _min, _max) do; 0; end
  def zcount(name, min, max) do
    GenServer.call name, {:zcount, min, max}
  end

  def zrange(name, start, stop) do
    GenServer.call name, {:zrange, start, stop}
  end

  def handle_call({:zcount, min, max}, _from, %{items: items} = state) do
    count = items |> RemixDB.SortedSet.count_items_in_range(min, max)
    {:reply, count, state}
  end

  def handle_call({:zrange, start, stop}, _from, %{items: items} = state) do
    start = String.to_integer start
    stop = String.to_integer stop
    items_in_range = items |> RemixDB.SortedSet.to_list |> get_items_in_range(start, stop)
    {:reply, items_in_range, state}
  end

  def handle_call({:zscore, member}, _from, %{items: items} = state) do
    score = items |> RemixDB.SortedSet.score(member)
    {:reply, score, state}
  end

  def handle_call({:zrank, member}, _from, %{items: items} = state) do
    rank = items |> RemixDB.SortedSet.rank(member)
    {:reply, rank, state}
  end

  def handle_call(:zcard, _from, %{items: items} = state) do
    num_items = items |> RemixDB.SortedSet.size
    {:reply, num_items, state}
  end

  def handle_call({:zrem, args}, _from, %{items: items} = state) do
    {num_items_removed, updated_items} = RemixDB.SortedSet.remove(items, args)
    new_state = update_state updated_items, state
    {:reply, num_items_removed, new_state}
  end

  def handle_call({:zadd, args}, _from, %{items: items} = state) do
    new_items = args
    {num_items_added, updated_items} = add_items_to_tree items, new_items
    new_state = update_state updated_items, state
    {:reply, num_items_added, new_state}
  end

  defp add_items_to_tree(sorted_set, items_and_scores) do
    items = Enum.chunk(items_and_scores, 2)
    num_existing_items = Enum.reduce(items, 0, fn([_score, item], acc) ->
      case RemixDB.SortedSet.member?(sorted_set, item) do
        true -> (acc + 1)
        _    -> acc
      end
    end)
    num_items_added = (items  |> Enum.count) - num_existing_items
    updated_items = Enum.reduce(items, sorted_set, fn([score_str, item], acc) ->
      score = score_str |> String.to_integer
      RemixDB.SortedSet.insert(acc, item, score)
    end)
    {num_items_added, updated_items}
  end

  # SantoshTODO: Move this into a module
  # and alias it for all datastructures
  defp update_state(updated_items, state) do
    Dict.merge(state, %{items: updated_items})
  end

  defp get_items_in_range(items, start, stop) do
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
end

