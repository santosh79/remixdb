defmodule Remixdb.Benchmark do

  @host ~c"0.0.0.0"
  @port 6379

  def get_and_set(num_elms \\ 1_000, num_clients \\ 50) do
    clients = 1..num_clients
              |> Enum.map(fn(_) ->
                {:ok, client} = :eredis.start_link(@host, @port)
                client
              end)
    :timer.sleep 1_000

    {set_time, :ok} = :timer.tc(fn ->
      1..num_elms
      |> Enum.map(fn(x) ->
        Task.async(fn ->
          idx = rem(x, num_clients)
          client = clients |> Enum.at(idx)
          {:ok, val} = client |> :eredis.q(["SET", "FOO-#{x}", "BARNED-#{x}"])
          val
        end)
      end)
      |> Enum.each(&Task.await/1)
    end)

    {get_time, :ok} = :timer.tc(fn ->
      1..num_elms
      |> Enum.map(fn(x) ->
        Task.async(fn ->
          "a" = "a"
          val = "BARNED-#{x}"
          idx = rem(x, num_clients)
          client = clients |> Enum.at(idx)
          {:ok, ^val} = :eredis.q(client, ["GET", "FOO-#{x}"])
        end)
      end)
      |> Enum.each(&Task.await/1)
    end)

    {:set_time, set_time, :get_time, get_time, :num_elms, num_elms, :num_clients, num_clients}
  end
end

