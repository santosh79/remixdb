defmodule Remixdb.Benchmark do
  def get_and_set(num_elms \\ 1_000) do
    client = Exredis.start_using_connection_string("redis://127.0.0.1:6379")
    :timer.sleep 1_000

    set_time = :timer.tc(fn ->
      1..num_elms |> Enum.each(fn(x) ->
        client |> Exredis.query(["SET", "FOO-#{x}", "BARNED-#{x}"])
      end)
    end)

    get_time = :timer.tc(fn ->
      1..num_elms |> Enum.each(fn(x) ->
        "a" = "a"
        val = "BARNED-#{x}"
        ^val = Exredis.query(client, ["GET", "FOO-#{x}"])
      end)
    end)

    %{:set_time => set_time, :get_time => get_time}
  end
end

