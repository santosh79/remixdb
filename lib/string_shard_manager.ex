defmodule Remixdb.String.ShardManager do
  use GenServer

  @shard_count 1_000
  @name :remixdb_string_shard_manager

  def start_link(_args) do
    GenServer.start_link(__MODULE__, :ok, name: @name)
  end

  def init(:ok) do
    send(self(), :long_init)
    {:ok, []}
  end

  def get(key) do
    GenServer.call(@name, {:get, key})
  end

  def incr(key) do
    GenServer.call(@name, {:incr, key})
  end

  def decr(key) do
    GenServer.call(@name, {:decr, key})
  end

  def append(key, val) do
    GenServer.call(@name, {:append, key, val})
  end

  def getset(key, val) do
    GenServer.call(@name, {:getset, key, val})
  end

  def set(key, val) do
    GenServer.call(@name, {:set, key, val})
  end

  def incrby(key, val) do
    GenServer.call(@name, {:incrby, key, val})
  end

  def decrby(key, val) do
    GenServer.call(@name, {:decrby, key, val})
  end

  def flushall() do
    GenServer.call(@name, :flushall)
  end

  def dbsize() do
    GenServer.call(@name, :dbsize)
  end

  def rename(old_key_name, new_key_name) do
    GenServer.call(@name, {:rename, old_key_name, new_key_name})
  end

  def handle_call(:dbsize, _from, pids) do
    res =
      pids
      |> Enum.map(fn pid ->
        Task.async(fn ->
          Remixdb.String.dbsize(pid)
        end)
      end)
      |> Task.await_many()
      |> Enum.sum()

    {:reply, res, pids}
  end

  def handle_call(:flushall, _from, pids) do
    pids
    |> Enum.map(fn pid ->
      Task.async(fn ->
        :ok = Remixdb.String.flushall(pid)
      end)
    end)
    |> Task.await_many()

    {:reply, :ok, pids}
  end

  def handle_call({:get, key}, _from, pids) do
    shard = get_shard(key, pids)
    res = Remixdb.String.get(key, shard)
    {:reply, res, pids}
  end

  def handle_call({:incr, key}, _from, pids) do
    shard = get_shard(key, pids)
    res = Remixdb.String.incr(key, shard)
    {:reply, res, pids}
  end

  def handle_call({:decr, key}, _from, pids) do
    shard = get_shard(key, pids)
    res = Remixdb.String.decr(key, shard)
    {:reply, res, pids}
  end

  def handle_call({:append, key, val}, _from, pids) do
    shard = get_shard(key, pids)
    res = Remixdb.String.append(key, val, shard)
    {:reply, res, pids}
  end

  def handle_call({:getset, key, val}, _from, pids) do
    shard = get_shard(key, pids)
    res = Remixdb.String.getset(key, val, shard)
    {:reply, res, pids}
  end

  def handle_call({:set, key, val}, _from, pids) do
    shard = get_shard(key, pids)
    res = Remixdb.String.set(key, val, shard)
    {:reply, res, pids}
  end

  def handle_call({:incrby, key, val}, _from, pids) do
    shard = get_shard(key, pids)
    res = Remixdb.String.incrby(key, val, shard)
    {:reply, res, pids}
  end

  def handle_call({:decrby, key, val}, _from, pids) do
    shard = get_shard(key, pids)
    res = Remixdb.String.decrby(key, val, shard)
    {:reply, res, pids}
  end

  def handle_call({:rename, old_key_name, new_key_name}, _from, pids) do
    old_key_shard = get_shard(old_key_name, pids)
    new_key_shard = get_shard(new_key_name, pids)
    old_key_val = Remixdb.String.get(old_key_name, old_key_shard)

    response =
      case old_key_val do
        nil ->
          false

        _ ->
          :ok = Remixdb.String.delete(old_key_name, old_key_shard)
          :ok = Remixdb.String.set(new_key_name, old_key_val, new_key_shard)
          true
      end

    {:reply, response, pids}
  end

  def handle_info(:long_init, _state) do
    state =
      _pids =
      Enum.map(1..@shard_count, fn i ->
        name = get_shard_name(i)
        :io.format("name long_init: ~p~n", [name])
        {:ok, pid} = Remixdb.String.start_link(name)
        pid
      end)

    {:noreply, state}
  end

  def handle_info(msg, state) do
    # Log the unexpected message for debugging purposes
    :io.format("Unhandled message in StringShardManager: ~p~n", [msg])
    # Logger.warn("Unhandled message in StringShardManager: #{inspect(msg)}")
    {:noreply, state}
  end

  defp get_shard_name(idx) do
    "remixdb_string_shard_#{idx}" |> String.to_atom()
  end

  defp get_shard(key, pids) do
    shard_number = :erlang.phash2(key, @shard_count)
    Enum.at(pids, shard_number)
  end
end
