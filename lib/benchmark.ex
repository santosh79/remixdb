defmodule Remixdb.Benchmark do
  def get_and_set(num_elms \\ 1_000, num_clients \\ 50, host \\ "127.0.0.1", port \\ "6379") do
    clients = 1..num_clients
              |> Enum.map(fn(_) ->
                Exredis.start_using_connection_string("redis://#{host}:#{port}")
              end)
    :timer.sleep 1_000

    {set_time, :ok} = :timer.tc(fn ->
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

    {get_time, :ok} = :timer.tc(fn ->
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

    {:set_time, set_time, :get_time, get_time, :num_elms, num_elms, :num_clients, num_clients}
  end
end

