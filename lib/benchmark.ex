defmodule Remixdb.Benchmark do
  def simple_get_set(num_keys \\ 1_000_000) do
    _ = Remixdb.Server.start_link
    client = Exredis.start_using_connection_string("redis://127.0.0.1:6379")
    :timer.sleep 1_000
    # keys and values
    k_and_v = 1..num_keys
              |> Enum.map(fn(_) ->
                # rand number
                rn = :rand.uniform(num_keys * 10)
                key = "key-#{rn}"
                val = "val-#{rn}"
                {key, val}
              end)
    :timer.tc(fn ->
      k_and_v |> Enum.map(fn({k, v}) ->
        client |> Exredis.query(["SET", k, v])
        val = client |> Exredis.query(["GET", k])
        ^v = val
      end)
    end)
  end
end
