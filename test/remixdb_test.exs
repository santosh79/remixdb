defmodule RemixdbTest do
  defmodule Server do
    use ExUnit.Case

    defp start_server do
      Remixdb.Server.start
    end

    test "set and get" do
      Remixdb.Server.start
      client = Exredis.start_using_connection_string("redis://127.0.0.1:6379")
      client |> Exredis.query ["SET", "FOO", "BAR"]
      val = client |> Exredis.query ["GET", "FOO"]
      assert val === "BAR"
      :timer.sleep 1000
      client |> Exredis.stop
    end
  end
end
