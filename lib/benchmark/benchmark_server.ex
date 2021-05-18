defmodule Remixdb.BenchmarkServer do
  use GenServer

  @name :remixdb_benchmark_server

  def start_link([]) do
    start_link 1_000, 50
  end

  def start_link(num_elms, num_clients) do
    GenServer.start_link __MODULE__, %{num_clients: num_clients, num_elms: num_elms}, name: @name
  end

  def init(state) do
    send self(), :benchmark
    {:ok, state}
  end

  def handle_info(:benchmark, %{num_elms: num_elms, num_clients: num_clients} = state) do
    res = get_and_set num_elms, num_clients
    :io.format("~p -- benchmark results: ~p~n", [__MODULE__, res])
    :timer.sleep 500
    send self(), :benchmark
    {:noreply, state}
  end

  defp get_and_set(num_elms, num_clients) do
    clients = 1..num_clients
    |> Enum.map(fn(_) ->
      Exredis.start_using_connection_string("redis://127.0.0.1:6379")
    end)
    :timer.sleep 1_000

    set_time = :timer.tc(fn ->
      1..num_elms
      |> Enum.map(fn(x) ->
        Task.async(fn ->
          idx = rem(x, num_clients)
          client = clients |> Enum.at(idx)
          client |> Exredis.query(["SET", "FOO-#{x}", "BARNED-#{x}"])
        end)
      end)
      |> Enum.each(&Task.await/1)
    end)

    get_time = :timer.tc(fn ->
      1..num_elms
      |> Enum.map(fn(x) ->
        Task.async(fn ->
          "a" = "a"
          val = "BARNED-#{x}"
          idx = rem(x, num_clients)
          client = clients |> Enum.at(idx)
          ^val = Exredis.query(client, ["GET", "FOO-#{x}"])
        end)
      end)
      |> Enum.each(&Task.await/1)
    end)

    clients |> Enum.map(fn(cc) ->
      :ok = Exredis.stop(cc)
    end)

    %{:set_time => set_time, :get_time => get_time}
  end
end
