defmodule RemixdbTest do
  defmodule Server do
    use ExUnit.Case

    setup_all context do
      Remixdb.Server.start
      client = Exredis.start_using_connection_string("redis://127.0.0.1:6379")
      {:ok, %{client: client}}
    end

    setup context do
      %{client: client} = context
      client |> Exredis.query(["FLUSHALL"])
      {:ok, %{client: client}}
    end

    test "exists", %{client: client} do
      val = client |> Exredis.query(["EXISTS", "NON-EXISTENT-KEY"])
      assert val === "0"

      client |> Exredis.query(["SET", "FOO", "BARNED"])
      val = client |> Exredis.query(["EXISTS", "FOO"])
      assert val === "1"
    end

    test "set and get", %{client: client} do
      client |> Exredis.query(["SET", "FOO", "BARNED"])
      val = client |> Exredis.query(["GET", "FOO"])
      assert val === "BARNED"
    end

    test "getset", %{client: client} do
      val = client |> Exredis.query(["GETSET", "FOO", "HEY"])
      assert val === :undefined

      val = client |> Exredis.query(["GETSET", "FOO", "BYE"])
      assert val === "HEY"

      val = client |> Exredis.query(["GET", "FOO"])
      assert val === "BYE"
    end

    test "get non-existent key", %{client: client} do
      val = client |> Exredis.query(["GET", "NON-EXISTENT-KEY"])
      assert val === :undefined
    end

    test "dbsize", %{client: client} do
      prev_db_size = client |> Exredis.query(["DBSIZE"]) |> String.to_integer
      1..1_000 |> Enum.each(fn(x) ->
        key = "temp_key" <> (x |> Integer.to_string)
        client |> Exredis.query(["SET", key, x])
      end)
      val = client |> Exredis.query(["DBSIZE"]) |> String.to_integer
      assert val === (prev_db_size + 1_000)
    end

    test "ping", %{client: client} do
      val = client |> Exredis.query(["PING"])
      assert val === "PONG"
      val = client |> Exredis.query(["PING", "hello world"])
      assert val === "hello world"
    end

    test "append - NON existing key", %{client: client} do
      val = client |> Exredis.query(["APPEND", "foo", "bar"])
      assert val === "3"

      val = client |> Exredis.query(["GET", "foo"])
      assert val === "bar"
    end

    test "INCR", %{client: client} do
      val = client |> Exredis.query(["INCR", "counter"])
      assert val === "1"

      val = client |> Exredis.query(["INCR", "counter"])
      assert val === "2"
    end

    test "INCRBY", %{client: client} do
      val = client |> Exredis.query(["INCRBY", "counter", 5])
      assert val === "5"

      val = client |> Exredis.query(["INCRBY", "counter", 10])
      assert val === "15"
    end

    test "append - existing key", %{client: client} do
      val = client |> Exredis.query(["SET", "mykey", "hello"])
      val = client |> Exredis.query(["APPEND", "mykey", " world"])
      assert val === "11"

      val = client |> Exredis.query(["GET", "mykey"])
      assert val === "hello world"
    end

    test "flushall", %{client: client} do
      client |> Exredis.query(["SET", "A", "1"])
      db_sz = client |> Exredis.query(["DBSIZE"]) |> String.to_integer
      assert db_sz > 0

      val = client |> Exredis.query(["FLUSHALL"])
      assert val === "OK"
      new_db_sz = client |> Exredis.query(["DBSIZE"]) |> String.to_integer
      assert new_db_sz === 0
      # assert val === (prev_db_size + 2)
    end
  end
end

