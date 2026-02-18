defmodule Remixdb.BM.String do
  use GenServer

  @host ~c"0.0.0.0"
  @port 6379

  def start_link([]) do
    GenServer.start_link(__MODULE__, %{})
  end

  def init(state) do
    send(self(), :long_init)
    {:ok, state}
  end

  @doc """
  Runs a simple benchmark against remixdb with
  - 2 parallel socket connections
  - 20 runs
  - during each run it does 1,000 gets and sets
  """
  def simple_bm() do
    run_bm(2, 20)
  end

  def profile_bm(num_elms \\ 1_000) do
    # Start your server
    {:ok, _} = Remixdb.start(:normal, [])
    
    # Start eredis client
    {:ok, client} = :eredis.start_link(~c"0.0.0.0", 6379)
    
    # Warm up
    kvs = create_key_vals(100)
    Enum.each(kvs, fn {k, v} -> :eredis.q(client, ["SET", k, v]) end)
    
    # Profile the actual work
    :fprof.trace([:start, procs: :all])
    
    kvs = create_key_vals(num_elms)
    Enum.each(kvs, fn {k, v} -> :eredis.q(client, ["SET", k, v]) end)
    Enum.each(kvs, fn {k, _v} -> :eredis.q(client, ["GET", k]) end)
    
    :fprof.trace(:stop)
    :fprof.profile()
    :fprof.analyse(dest: ~c"profile_results.txt")
    
    :eredis.stop(client)
  end

  def run_bm(num_connections \\ 10, num_times \\ 50, num_elms \\ 1_000) do
    1..num_connections
    |> Enum.map(fn _ ->
      {:ok, pp} = Remixdb.BM.String.start_link([])
      pp
    end)
    |> Enum.map(fn pid ->
      Remixdb.BM.String.bm(pid, num_times, num_elms)
    end)
  end

  def bm(pid) when is_pid(pid) do
    bm(pid, 50, 10_000)
  end

  @doc """
  Runs a benchmark against remixdb with
  - 1 socket connection
  - num_times number of runs
  - during each run it does num_elms gets and sets
  """
  def bm(pid, num_times, num_elms) when is_pid(pid) do
    GenServer.cast(pid, {:benchmark, 0, num_times, pid, num_elms, []})
  end

  def handle_info(:long_init, state) do
    {:ok, client} = :eredis.start_link(@host, @port)
    :timer.sleep(1_000)
    updated_state = state |> Map.put(:client, client)
    {:noreply, updated_state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  def handle_cast({:stop, num_elms}, %{client: client, results: res} = state) do
    :ok = client |> :eredis.stop()
    :timer.sleep(300)
    print_results(res, num_elms)
    {:stop, :normal, state}
  end

  def handle_cast(
        {:benchmark, num_times, num_times, pid, num_elms, results},
        %{client: _client} = state
      ) do
    :io.format("~p with pid: ~p -- DONE! ~n", [__MODULE__, pid])
    GenServer.cast(pid, {:stop, num_elms})

    updated_state = Map.put(state, :results, results)
    {:noreply, updated_state}
  end

  def handle_cast(
        {:benchmark, num_runs, num_times, pid, num_elms, results},
        %{client: client} = state
      ) do
    res = get_and_set(num_elms, client)
    GenServer.cast(pid, {:benchmark, num_runs + 1, num_times, pid, num_elms, [res | results]})
    {:noreply, state}
  end

  defp get_and_set(num_elms, client) do
    kvs = create_key_vals(num_elms)

    set_time =
      :timer.tc(fn ->
        kvs
        |> Enum.map(fn {key, val} ->
          Task.async(fn ->
            {:ok, "OK"} = client |> :eredis.q(["SET", key, val])
          end)
        end)
        |> Enum.each(&Task.await/1)
      end)

    get_time =
      :timer.tc(fn ->
        kvs
        |> Enum.map(fn {key, val} ->
          Task.async(fn ->
            {:ok, ^val} = :eredis.q(client, ["GET", key])
          end)
        end)
        |> Enum.each(&Task.await/1)
      end)

    %{:set_time => set_time, :get_time => get_time}
  end

  defp print_results(results, num_elms) do
    num_runs = Enum.count(results)

    max_get = get_results(results, :get_time, :max)
    min_get = get_results(results, :get_time, :min)
    get_sum = get_results(results, :get_time, :sum)
    avg_get = get_sum * 1.0 / num_runs

    max_set = get_results(results, :set_time, :max)
    min_set = get_results(results, :set_time, :min)
    set_sum = get_results(results, :set_time, :sum)
    avg_set = set_sum * 1.0 / num_runs

    num_runs = results |> Enum.count()
    sep = String.duplicate("=", 50)

    str = """
    ~n~n~s~nnum_runs: ~p
    pid: ~p ~nnum_elms: ~p

    GET RESULTS:
    min: ~p
    max: ~p
    avg: ~p

    SET RESULTS:
    min: ~p
    max: ~p
    avg: ~p
    ~s
    """

    :io.format(str, [
      sep,
      num_runs,
      self(),
      num_elms,
      min_get,
      max_get,
      avg_get,
      min_set,
      max_set,
      avg_set,
      sep
    ])
  end

  defp get_results(results, map_key, enum_func) do
    res =
      results
      |> Enum.map(fn cc ->
        {res, :ok} = Map.get(cc, map_key)
        res
      end)

    :erlang.apply(Enum, enum_func, [res])
  end

  defp create_key_vals(num_elms) do
    1..num_elms
    |> Enum.reduce(Map.new(), fn _, acc ->
      key = :erlang.make_ref() |> inspect()
      val = :erlang.make_ref() |> inspect()
      Map.put(acc, key, val)
    end)
  end
end
