defmodule Remixdb.BM do
  use GenServer

  def start_link([]) do
    GenServer.start_link __MODULE__, %{}
  end

  def init(state) do
    send self(), :long_init
    {:ok, state}
  end

  def bm(pid) when is_pid(pid) do
    bm pid, 50, 10_000
  end

  def bm(pid, num_times, num_elms) when is_pid(pid) do
    GenServer.cast pid, {:benchmark, num_times, pid, num_elms}
  end

  def bm(num_connections \\ 10, num_times \\ 50, num_elms \\ 1_000) do
    1..num_connections
    |> Enum.map(fn(_) ->
      {:ok, pp} = Remixdb.BM.start_link []
      pp
    end)
    |> Enum.map(fn(pid) ->
      Remixdb.BM.bm(pid, num_times, num_elms)
    end)
  end

  def handle_info(:long_init, state) do
    client = Exredis.start_using_connection_string("redis://127.0.0.1:6379")
    :timer.sleep 1_000
    updated_state = state |> Map.put(:client, client)
    {:noreply, updated_state}
  end

  def handle_cast(:stop, %{client: client} = state) do
    :ok = client |> Exredis.stop
    :timer.sleep 300
    {:stop, "Finished benchmarking", state}
  end

  def handle_cast({:benchmark, 0, pid}, %{num_elms: num_elms, client: client} = state) do
    :io.format("~p with pid: ~p -- DONE! ~n", [__MODULE__, pid])
    GenServer.cast pid, :stop

    {:noreply, state}
  end

  def handle_cast({:benchmark, num_times, pid, num_elms}, %{client: client} = state) when num_times > 0 do
    res = get_and_set num_elms, client
    :io.format("~p current: ~p, pid: ~p, benchmark results: ~p~n", [__MODULE__, num_times, pid, res])
    :timer.sleep 500
    GenServer.cast pid, {:benchmark, num_times - 1, pid, num_times}
    {:noreply, state}
  end


  def handle_info(_, state) do
    {:noreply, state}
  end

  defp get_and_set(num_elms, client) do
    kvs =  1..num_elms
    |> Enum.reduce(Map.new, fn(_, acc) ->
      key = UUID.uuid4
      val = UUID.uuid4
      Map.put(acc, key, val)
    end)

    set_time = :timer.tc(fn ->
      kvs
      |> Enum.map(fn({key, val}) ->
        Task.async(fn ->
          client |> Exredis.query(["SET", key, val])
        end)
      end)
      |> Enum.each(&Task.await/1)
    end)

    get_time = :timer.tc(fn ->
      kvs
      |> Enum.map(fn({key, val}) ->
        Task.async(fn ->
          ^val = Exredis.query(client, ["GET", key])
        end)
      end)
      |> Enum.each(&Task.await/1)
    end)

    %{:set_time => set_time, :get_time => get_time}
  end
end
