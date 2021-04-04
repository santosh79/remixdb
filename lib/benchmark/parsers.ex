defmodule Remixdb.Benchmark.Parsers do
  def redis_parser_bm(num_items \\ 1_000) do
    :timer.sleep 1_000
    client = Exredis.start_using_connection_string("redis://127.0.0.1:6379")
    :timer.sleep 1_000
    keys_and_vals = 1..num_items
                    |> Enum.map(&( {"key: #{&1}", "val: #{&1}"} ))

    result = :timer.tc(fn ->
      t_ids = keys_and_vals |> Enum.map(fn({k, v}) ->
        Task.async __MODULE__, :set_task, [client, k, v]
      end)

      t_ids |> Enum.each(fn(t_id) ->
        Task.await t_id
      end)
    end)
    :ok = client |> Exredis.stop()
    :io.format("~n~n ~p with result: ~p ~n~n", [__MODULE__, result])
    :timer.sleep(:timer.seconds(2))
    Process.exit(self(), :kill)
  end


  def set_task(client, k, v) do
    "OK" = client |> Exredis.query(["SET", k, v])
  end

  def set_task_old(client, keys_and_vals) do
    keys_and_vals |> Enum.each(fn({k, v}) ->
      "OK" = client |> Exredis.query(["SET", k, v])
    end)
  end
end

