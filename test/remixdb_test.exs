defmodule RemixdbTest do
  defmodule Server do
    use ExUnit.Case

    setup_all context do
      Remixdb.Server.start
      :ok
    end

    test "exists" do
      client = Exredis.start_using_connection_string("redis://127.0.0.1:6379")
      val = client |> Exredis.query ["EXISTS", "NON-EXISTENT-KEY"]
      assert val === "0"

      client |> Exredis.query ["SET", "FOO", "BARNED"]
      val = client |> Exredis.query ["EXISTS", "FOO"]

      assert val === "1"
      client |> Exredis.stop
    end

    test "set and get" do
      client = Exredis.start_using_connection_string("redis://127.0.0.1:6379")
      client |> Exredis.query ["SET", "FOO", "BARNED"]
      val = client |> Exredis.query ["GET", "FOO"]
      assert val === "BARNED"
      client |> Exredis.stop
    end

    test "get non-existent key" do
      client = Exredis.start_using_connection_string("redis://127.0.0.1:6379")
      val = client |> Exredis.query ["GET", "NON-EXISTENT-KEY"]
      assert val === :undefined
      client |> Exredis.stop
    end

  end
end
