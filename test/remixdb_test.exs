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

    test "DECR", %{client: client} do
      val = client |> Exredis.query(["DECR", "counter"])
      assert val === "-1"

      client |> Exredis.query(["INCR", "counter"])
      client |> Exredis.query(["INCR", "counter"])
      val = client |> Exredis.query(["DECR", "counter"])
      assert val === "0"
    end

    test "DECRBY", %{client: client} do
      val = client |> Exredis.query(["DECRBY", "counter", 5])
      assert val === "-5"

      client |> Exredis.query(["INCRBY", "counter", 10])
      val = client |> Exredis.query(["DECRBY", "counter", 5])
      assert val === "0"
    end

    test "append - existing key", %{client: client} do
      val = client |> Exredis.query(["SET", "mykey", "hello"])
      val = client |> Exredis.query(["APPEND", "mykey", " world"])
      assert val === "11"

      val = client |> Exredis.query(["GET", "mykey"])
      assert val === "hello world"
    end

    @tag slow: true
    test "SETEX & TTL", %{client: client} do
      val = client |> Exredis.query(["SETEX", "mykey", 1, "hello"])
      assert val === "OK"

      val = client |> Exredis.query(["TTL", "mykey"])
      assert val === "1"

      val = client |> Exredis.query(["GET", "mykey"])
      assert val === "hello"

      :timer.sleep 1_500
      val = client |> Exredis.query(["GET", "mykey"])
      assert val === :undefined

      val = client |> Exredis.query(["TTL", "mykey"])
      assert val === "-2"
    end

    test "RENAME", %{client: client} do
      val = client |> Exredis.query(["SET", "mykey", "hello"])
      val = client |> Exredis.query(["RENAME", "mykey", "foo"])
      assert val === "OK"

      val = client |> Exredis.query(["GET", "foo"])
      assert val === "hello"

      val = client |> Exredis.query(["GET", "mykey"])
      assert val === :undefined

      val = client |> Exredis.query(["RENAME", "unknown_key", "bar"])
      assert val === "ERR no such key"
    end

    test "RENAMENX", %{client: client} do
      val = client |> Exredis.query(["SET", "mykey", "hello"])
      val = client |> Exredis.query(["RENAMENX", "mykey", "foo"])
      assert val === "1"

      val = client |> Exredis.query(["SET", "mykey", "hello"])
      val = client |> Exredis.query(["RENAMENX", "foo", "mykey"])
      assert val === "0"

      val = client |> Exredis.query(["RENAMENX", "unknown_key", "something"])
      assert val === "ERR no such key"
    end

    test "RPOP & LPUSH", %{client: client} do
      val = client |> Exredis.query(["RPUSH", "mylist", "three", "four", "five", "six"])
      assert val === "4"

      val = client |> Exredis.query(["LPUSH", "mylist", "two"])
      val = client |> Exredis.query(["LPUSH", "mylist", "one"])
      assert val === "6"

      val = client |> Exredis.query(["RPOP", "mylist"])
      assert val === "six"

      val = client |> Exredis.query(["LPOP", "mylist"])
      assert val === "one"

      (1..4) |> Enum.each(fn(_x) ->
        client |> Exredis.query(["LPOP", "mylist"])
      end)
      val = client |> Exredis.query(["LPOP", "mylist"])
      assert val === :undefined
    end

    test "LRANGE", %{client: client} do
      client |> Exredis.query(["RPUSH", "mylist", "one"])
      client |> Exredis.query(["RPUSH", "mylist", "two"])
      client |> Exredis.query(["RPUSH", "mylist", "three"])

      val = client |> Exredis.query(["LRANGE", "mylist", 0, -1])
      assert val === ["one", "two", "three"]

      val = client |> Exredis.query(["LRANGE", "mylist", 0, 0])
      assert val === ["one"]

      val = client |> Exredis.query(["LRANGE", "mylist", -3, -2])
      assert val === ["one", "two"]

      val = client |> Exredis.query(["LRANGE", "mylist", -100, 100])
      assert val === ["one", "two", "three"]

      val = client |> Exredis.query(["LRANGE", "mylist", 5, 10])
      assert val === []

      val = client |> Exredis.query(["LRANGE", "mylist", -100, 0])
      assert val === ["one"]

      val = client |> Exredis.query(["LRANGE", "unknown_list", 5, 10])
      assert val === []
    end

    test "LPUSHX & RPUSHX", %{client: client} do
      val = client |> Exredis.query(["LPUSH", "mylist", "world"])
      assert val === "1"

      val = client |> Exredis.query(["LPUSHX", "mylist", "Hello"])
      assert val === "2"

      val = client |> Exredis.query(["RPUSHX", "mylist", "There"])
      assert val === "3"

      val = client |> Exredis.query(["LPUSHX", "unknown_list", "Hello"])
      assert val === "0"

      val = client |> Exredis.query(["RPUSHX", "unknown_list", "Hello"])
      assert val === "0"

      val = client |> Exredis.query(["LLEN", "mylist"])
      assert val === "3"

      val = client |> Exredis.query(["LLEN", "unknown_list"])
      assert val === "0"

      val = client |> Exredis.query(["EXISTS", "unknown_list"])
      assert val === "0"
    end

    test "LPOP, RPUSH & LLEN", %{client: client} do
      val = client |> Exredis.query(["LLEN", "mylist"])
      assert val === "0"

      val = client |> Exredis.query(["RPUSH", "mylist", "one",  "two"])
      assert val === "2"
      val = client |> Exredis.query(["RPUSH", "mylist", "three"])
      assert val === "3"

      val = client |> Exredis.query(["LLEN", "mylist"])
      assert val === "3"

      val = client |> Exredis.query(["LPOP", "mylist"])
      assert val === "one"

      client |> Exredis.query(["LPOP", "mylist"])
      client |> Exredis.query(["LPOP", "mylist"])
      val = client |> Exredis.query(["LPOP", "mylist"])
      assert val === :undefined

      val = client |> Exredis.query(["EXISTS", "mylist"])
      assert val === "0"

      val = client |> Exredis.query(["LPOP", "unknown_list"])
      assert val === :undefined
    end

    test "RPOPLPUSH", %{client: client} do
      ["one", "two", "three"] |> Enum.each(fn(el) ->
        client |> Exredis.query(["RPUSH", "mylist", el])
      end)

      val = client |> Exredis.query(["RPOPLPUSH", "mylist", "myotherlist"])
      assert val === "three"

      val = client |> Exredis.query(["LRANGE", "mylist", 0, -1])
      assert val === ["one", "two"]

      val = client |> Exredis.query(["LRANGE", "myotherlist", 0, -1])
      assert val === ["three"]

      val = client |> Exredis.query(["RPOPLPUSH", "unknown_list", "myotherlist"])
      assert val === :undefined

      val = client |> Exredis.query(["LRANGE", "myotherlist", 0, -1])
      assert val === ["three"]
    end

    @tag slow: true, skip: true
    test "EXPIRE", %{client: client} do
      val = client |> Exredis.query(["SET", "mykey", "hello"])
      assert val === "OK"

      val = client |> Exredis.query(["EXPIRE", "mykey", 1])
      assert val === "1"

      val = client |> Exredis.query(["TTL", "mykey"])
      assert val === "1"

      :timer.sleep 1_200
      val = client |> Exredis.query(["TTL", "mykey"])
      assert val === "-2"

      val = client |> Exredis.query(["GET", "mykey"])
      assert val === :undefined
    end

    @tag slow: true, skip: true
    test "PERSIST", %{client: client} do
      val = client |> Exredis.query(["SET", "mykey", "hello"])
      assert val === "OK"

      val = client |> Exredis.query(["EXPIRE", "mykey", 1])
      assert val === "1"

      val = client |> Exredis.query(["PERSIST", "mykey"])
      assert val === "1"

      val = client |> Exredis.query(["TTL", "mykey"])
      assert val === "-1"

      :timer.sleep 1_200
      val = client |> Exredis.query(["GET", "mykey"])
      assert val === "hello"

      val = client |> Exredis.query(["PERSIST", "unknown_key"])
      assert val === "0"

      val = client |> Exredis.query(["TTL", "unknown_key"])
      assert val === "-2"
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

