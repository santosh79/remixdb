defmodule Remixdb.Benchmark.Parsers do

  @host ~c"0.0.0.0"
  @port 6379

  def redis_parser_bm(num_items \\ 1_000, num_workers \\ 50) do
    :timer.sleep 1_000
    {:ok, client} = :eredis.start_link(@host, @port)
    :timer.sleep 1_000
    keys_and_vals = 1..num_items
                    |> Enum.map(&( {"key: #{&1}", "val: #{&1}"} ))

    worker_buckets = keys_and_vals |> Enum.chunk_every(num_workers)

    set_result = :timer.tc(fn ->
      t_ids = worker_buckets |> Enum.map(fn(bucket) ->
        Task.async(fn ->
          tts = bucket |> Enum.map(fn({k, v}) ->
            Task.async __MODULE__, :set_task, [client, k, v]
          end)

          tts |> Enum.each(fn(t_id) ->
            Task.await t_id
          end)
        end)
      end)

      t_ids |> Enum.each(fn(t_id) ->
        Task.await t_id
      end)

    end)

    get_result = :timer.tc(fn ->
      t_ids = worker_buckets |> Enum.map(fn(bucket) ->
        Task.async(fn ->
          tts = bucket |> Enum.map(fn({k, v}) ->
            Task.async __MODULE__, :get_task, [client, k, v]
          end)

          tts |> Enum.each(fn(t_id) ->
            Task.await t_id
          end)
        end)
      end)

      t_ids |> Enum.each(fn(t_id) ->
        Task.await t_id
      end)

    end)

    :ok = client |> :eredis.stop()

    :io.format("~n~n ~p with num_items: ~p and num_workers ~p, result, set -- ~p, get -- ~p ~n~n", [__MODULE__, num_items, num_workers, set_result, get_result])
    :timer.sleep(:timer.seconds(2))
    Process.exit(self(), :kill)
  end


  def set_task(client, k, v) do
    {:ok, "OK"} = client |> :eredis.q(["SET", k, v])
  end

  def get_task(client, k, v) do
    client |> :eredis.q(["SET", k, v])
  end
end

