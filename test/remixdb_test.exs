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

    test "dbsize" do
      client = Exredis.start_using_connection_string("redis://127.0.0.1:6379")
      prev_db_size = client |> Exredis.query(["DBSIZE"]) |> String.to_integer
      1..1_000 |> Enum.each(fn(x) ->
        key = "temp_key" <> (x |> Integer.to_string)
        client |> Exredis.query(["SET", key, x])
      end)
      val = client |> Exredis.query(["DBSIZE"]) |> String.to_integer
      assert val === (prev_db_size + 1_000)
      client |> Exredis.stop
    end

    test "ping" do
      client = Exredis.start_using_connection_string("redis://127.0.0.1:6379")
      val = client |> Exredis.query ["PING"]
      assert val === "PONG"
      val = client |> Exredis.query ["PING", "hello world"]
      assert val === "hello world"
    end

    test "append - NON existing key" do
      client = Exredis.start_using_connection_string("redis://127.0.0.1:6379")
      client |> Exredis.query ["FLUSHALL"]

      val = client |> Exredis.query ["APPEND", "foo", "bar"]
      assert val === "3"

      val = client |> Exredis.query ["GET", "foo"]
      assert val === "bar"
    end

    test "append - existing key" do
      client = Exredis.start_using_connection_string("redis://127.0.0.1:6379")
      client |> Exredis.query ["FLUSHALL"]

      val = client |> Exredis.query ["SET", "mykey", "hello"]
      val = client |> Exredis.query ["APPEND", "mykey", " world"]
      assert val === "11"

      val = client |> Exredis.query ["GET", "mykey"]
      assert val === "hello world"
    end

    test "flushall" do
      client = Exredis.start_using_connection_string("redis://127.0.0.1:6379")
      client |> Exredis.query ["SET", "A", "1"]
      db_sz = client |> Exredis.query(["DBSIZE"]) |> String.to_integer
      assert db_sz > 0

      val = client |> Exredis.query ["FLUSHALL"]
      assert val === "OK"
      new_db_sz = client |> Exredis.query(["DBSIZE"]) |> String.to_integer
      assert new_db_sz === 0
      # assert val === (prev_db_size + 2)
      client |> Exredis.stop
    end
  end
end

