defmodule RemixdbTest do
  defmodule Server do
    use ExUnit.Case

    @host ~c"0.0.0.0"
    @port 6379

    setup_all _context do
      {:ok, client} = :eredis.start_link(@host, @port)
      :timer.sleep(1_000)
      {:ok, %{client: client}}
    end

    setup context do
      %{client: client} = context
      {:ok, "OK"} = client |> :eredis.q(["FLUSHALL"])
      {:ok, %{client: client}}
    end

    test "exists", %{client: client} do
      non_exist_key = :erlang.make_ref() |> inspect()
      key = :erlang.make_ref() |> inspect()

      {:ok, val} = client |> :eredis.q(["EXISTS", non_exist_key])
      assert val === "0"

      vv = :erlang.make_ref() |> inspect()
      client |> :eredis.q(["SET", key, vv])
      {:ok, val} = client |> :eredis.q(["EXISTS", key])
      assert val === "1"
    end

    test "set and get", %{client: client} do
      key = :erlang.make_ref() |> inspect()
      vv = :erlang.make_ref() |> inspect()
      client |> :eredis.q(["SET", key, vv])
      {:ok, val} = client |> :eredis.q(["GET", key])
      assert val === vv
    end

    test "getset", %{client: client} do
      key = :erlang.make_ref() |> inspect()
      vv = :erlang.make_ref() |> inspect()

      {:ok, val} = client |> :eredis.q(["GETSET", key, vv])
      assert val === :undefined

      vv_n = :erlang.make_ref() |> inspect()
      {:ok, val} = client |> :eredis.q(["GETSET", key, vv_n])
      assert val === vv

      {:ok, val} = client |> :eredis.q(["GET", key])
      assert val === vv_n
    end

    test "get non-existent key", %{client: client} do
      non_exist_key = :erlang.make_ref() |> inspect()
      {:ok, val} = client |> :eredis.q(["GET", non_exist_key])
      assert val === :undefined
    end

    test "dbsize", %{client: client} do
      {:ok, prev_db_size} = client |> :eredis.q(["DBSIZE"])
      prev_db_size = prev_db_size |> String.to_integer()

      1..1_000
      |> Enum.each(fn _x ->
        val = key = :erlang.make_ref() |> inspect()
        client |> :eredis.q(["SET", key, val])
      end)

      1..1_000
      |> Enum.each(fn _x ->
        val = key = :erlang.make_ref() |> inspect()
        client |> :eredis.q(["LPUSH", key, val])
      end)

      1..1_000
      |> Enum.each(fn _x ->
        val = key = :erlang.make_ref() |> inspect()
        hash_name = :erlang.make_ref() |> inspect()
        client |> :eredis.q(["HSET", hash_name, key, val])
      end)

      1..1_000
      |> Enum.each(fn _x ->
        val = set_name = :erlang.make_ref() |> inspect()
        client |> :eredis.q(["SADD", set_name, val])
      end)

      {:ok, val} = client |> :eredis.q(["DBSIZE"])
      val =  val |> String.to_integer()
      assert val === prev_db_size + 4_000
    end

    test "ping", %{client: client} do
      {:ok, val} = client |> :eredis.q(["PING"])
      assert val === "PONG"
      {:ok, val} = client |> :eredis.q(["PING", "hello world"])
      assert val === "hello world"
    end

    test "append - NON existing key", %{client: client} do
      key = :erlang.make_ref() |> inspect()
      vv = :erlang.make_ref() |> inspect()

      {:ok, val} = client |> :eredis.q(["APPEND", key, vv])
      assert val === vv |> String.length() |> Integer.to_string()

      {:ok, val} = client |> :eredis.q(["GET", key])
      assert val === vv
    end

    test "INCR", %{client: client} do
      counter = :erlang.make_ref() |> inspect()
      {:ok, val} = client |> :eredis.q(["INCR", counter])
      assert val === "1"

      {:ok, val} = client |> :eredis.q(["INCR", counter])
      assert val === "2"
    end

    test "INCRBY", %{client: client} do
      counter = :erlang.make_ref() |> inspect()
      {:ok, val} = client |> :eredis.q(["INCRBY", counter, 5])
      assert val === "5"

      {:ok, val} = client |> :eredis.q(["INCRBY", counter, 10])
      assert val === "15"
    end

    test "DECR", %{client: client} do
      counter = :erlang.make_ref() |> inspect()
      {:ok, val} = client |> :eredis.q(["DECR", counter])
      assert val === "-1"

      client |> :eredis.q(["INCR", counter])
      client |> :eredis.q(["INCR", counter])
      {:ok, val} = client |> :eredis.q(["DECR", counter])
      assert val === "0"
    end

    test "DECRBY", %{client: client} do
      counter = :erlang.make_ref() |> inspect()
      {:ok, val} = client |> :eredis.q(["DECRBY", counter, 5])
      assert val === "-5"

      client |> :eredis.q(["INCRBY", counter, 10])
      {:ok, val} = client |> :eredis.q(["DECRBY", counter, 5])
      assert val === "0"
    end

    test "append - existing key", %{client: client} do
      mykey = :erlang.make_ref() |> inspect()
      client |> :eredis.q(["SET", mykey, "hello"])
      {:ok, val} = client |> :eredis.q(["APPEND", mykey, " world"])
      assert val === "11"

      {:ok, val} = client |> :eredis.q(["GET", mykey])
      assert val === "hello world"
    end

    # @tag slow: true
    @tag skip: true
    test "SETEX & TTL", %{client: client} do
      {:ok, val} = client |> :eredis.q(["SETEX", "mykey", 1, "hello"])
      assert val === "OK"

      {:ok, val} = client |> :eredis.q(["TTL", "mykey"])
      assert val === "1"

      {:ok, val} = client |> :eredis.q(["GET", "mykey"])
      assert val === "hello"

      :timer.sleep(1_500)
      {:ok, val} = client |> :eredis.q(["GET", "mykey"])
      assert val === :undefined

      {:ok, val} = client |> :eredis.q(["TTL", "mykey"])
      assert val === "-2"
    end

    test "RENAME", %{client: client} do
      kk = :erlang.make_ref() |> inspect()
      vv = :erlang.make_ref() |> inspect()

      {:ok, val} = client |> :eredis.q(["SET", kk, vv])
      assert val === "OK"

      new_kk = :erlang.make_ref() |> inspect()
      {:ok, val} = client |> :eredis.q(["RENAME", kk, new_kk])
      assert val === "OK"

      {:ok, val} = client |> :eredis.q(["GET", kk])
      assert val === :undefined

      {:ok, val} = client |> :eredis.q(["GET", new_kk])
      assert val === vv

      unknown_key = :erlang.make_ref() |> inspect()
      {:error, val} = client |> :eredis.q(["RENAME", unknown_key, :erlang.make_ref() |> inspect()])
      assert val === "ERR no such key"
    end

    test "RENAMENX works correctly for strings and lists", %{client: client} do
      ## STRING KEY CASES

      # Basic rename works
      client |> :eredis.q(["SET", "strkey", "hello"])
      {:ok, val} = client |> :eredis.q(["RENAMENX", "strkey", "strkey2"])
      assert val == "1"

      # Target exists, so renamenx should fail
      client |> :eredis.q(["SET", "strkey", "again"])
      {:ok, val} = client |> :eredis.q(["RENAMENX", "strkey2", "strkey"])
      assert val == "0"

      # Rename fails if source does not exist
      {:error, "ERR no such key"} = client |> :eredis.q(["RENAMENX", "nonexistent", "newname"])

      # Contents were moved correctly
      {:ok, val} = client |> :eredis.q(["GET", "strkey2"])
      assert val == "hello"

      {:ok, val} = client |> :eredis.q(["GET", "strkey"])
      assert val == "again"

      ## LIST KEY CASES

      # Setup list
      client |> :eredis.q(["DEL", "listA", "listB"])
      {:ok, "3"} = client |> :eredis.q(["RPUSH", "listA", "a", "b", "c"])
      {:ok, val} = client |> :eredis.q(["RENAMENX", "listA", "listB"])
      assert val == "1"

      # # Verify data moved
      {:ok, val} = client |> :eredis.q(["LRANGE", "listB", "0", "-1"])
      assert val == ["a", "b", "c"]

      {:ok, val} = client |> :eredis.q(["EXISTS", "listA"])
      assert val == "0"

      # # Try renaming again to listB, which already exists — should fail
      client |> :eredis.q(["RPUSH", "listA", "x", "y", "z"])
      {:ok, val} = client |> :eredis.q(["RENAMENX", "listA", "listB"])
      assert val == "0"

      # # Contents of listB should remain unchanged
      {:ok, val} = client |> :eredis.q(["LRANGE", "listB", "0", "-1"])
      assert val == ["a", "b", "c"]

      # # Contents of listA should still exist
      {:ok, val} = client |> :eredis.q(["LRANGE", "listA", "0", "-1"])
      assert val == ["x", "y", "z"]
    end

    test "RENAMENX", %{client: client} do
      client |> :eredis.q(["SET", "mykey", "hello"])
      {:ok, val} = client |> :eredis.q(["RENAMENX", "mykey", "foo"])
      assert val === "1"

      client |> :eredis.q(["SET", "mykey", "hello"])
      {:ok, val} = client |> :eredis.q(["RENAMENX", "foo", "mykey"])
      assert val === "0"

      {:error, "ERR no such key"} = client |> :eredis.q(["RENAMENX", "unknown_key", "something"])
    end

    ##
    # LISTS
    ##
    test "RPOP & LPUSH", %{client: client} do
      {:ok, val} = client |> :eredis.q(["RPUSH", "mylist", "three", "four", "five", "six"])
      assert val === "4"

      client |> :eredis.q(["LPUSH", "mylist", "two"])
      {:ok, val} = client |> :eredis.q(["LPUSH", "mylist", "one"])
      assert val === "6"

      {:ok, val} = client |> :eredis.q(["RPOP", "mylist"])
      assert val === "six"

      {:ok, val} = client |> :eredis.q(["LPOP", "mylist"])
      assert val === "one"

      1..4
      |> Enum.each(fn _x ->
        client |> :eredis.q(["LPOP", "mylist"])
      end)

      {:ok, val} = client |> :eredis.q(["LPOP", "mylist"])
      assert val === :undefined

      {:ok, val} = client |> :eredis.q(["RPOP", "mylist"])
      assert val === :undefined
    end

    test "LRANGE", %{client: client} do
      mylist = :erlang.make_ref() |> inspect()
      client |> :eredis.q(["RPUSH", mylist, "one"])
      client |> :eredis.q(["RPUSH", mylist, "two"])
      client |> :eredis.q(["RPUSH", mylist, "three"])

      {:ok, val} = client |> :eredis.q(["LRANGE", mylist, 0, -1])
      assert val === ["one", "two", "three"]

      {:ok, val} = client |> :eredis.q(["LRANGE", mylist, 0, 0])
      assert val === ["one"]

      {:ok, val} = client |> :eredis.q(["LRANGE", mylist, -3, -2])
      assert val === ["one", "two"]

      {:ok, val} = client |> :eredis.q(["LRANGE", mylist, -100, 100])
      assert val === ["one", "two", "three"]

      {:ok, val} = client |> :eredis.q(["LRANGE", mylist, 5, 10])
      assert val === []

      {:ok, val} = client |> :eredis.q(["LRANGE", mylist, -100, 0])
      assert val === ["one"]

      unknown_list = :erlang.make_ref() |> inspect()
      {:ok, val} = client |> :eredis.q(["LRANGE", unknown_list, 5, 10])
      assert val === []
    end

    test "LPUSHX & RPUSHX", %{client: client} do
      mylist = :erlang.make_ref() |> inspect()
      unknown_list = :erlang.make_ref() |> inspect()

      {:ok, val} = client |> :eredis.q(["LPUSH", mylist, "world"])
      assert val === "1"

      {:ok, val} = client |> :eredis.q(["LPUSHX", mylist, "Hello"])
      assert val === "2"

      {:ok, val} = client |> :eredis.q(["RPUSHX", mylist, "There"])
      assert val === "3"

      {:ok, val} = client |> :eredis.q(["LPUSHX", unknown_list, "Hello"])
      assert val === "0"

      {:ok, val} = client |> :eredis.q(["RPUSHX", unknown_list, "Hello"])
      assert val === "0"

      {:ok, val} = client |> :eredis.q(["LLEN", mylist])
      assert val === "3"

      {:ok, val} = client |> :eredis.q(["LLEN", unknown_list])
      assert val === "0"

      {:ok, val} = client |> :eredis.q(["EXISTS", unknown_list])
      assert val === "0"
    end

    test "LPOP, RPUSH & LLEN", %{client: client} do
      mylist = :erlang.make_ref() |> inspect()
      unknown_list = :erlang.make_ref() |> inspect()

      {:ok, val} = client |> :eredis.q(["LLEN", mylist])
      assert val === "0"

      {:ok, val} = client |> :eredis.q(["RPUSH", mylist, "one", "two"])
      assert val === "2"
      {:ok, val} = client |> :eredis.q(["RPUSH", mylist, "three"])
      assert val === "3"

      {:ok, val} = client |> :eredis.q(["LLEN", mylist])
      assert val === "3"

      {:ok, val} = client |> :eredis.q(["LPOP", mylist])
      assert val === "one"

      client |> :eredis.q(["LPOP", mylist])
      client |> :eredis.q(["LPOP", mylist])
      {:ok, val} = client |> :eredis.q(["LPOP", mylist])
      assert val === :undefined

      {:ok, val} = client |> :eredis.q(["EXISTS", mylist])
      assert val === "0"

      {:ok, val} = client |> :eredis.q(["LPOP", unknown_list])
      assert val === :undefined
    end

    test "RPOPLPUSH", %{client: client} do
      mylist = :erlang.make_ref() |> inspect()
      unknown_list = :erlang.make_ref() |> inspect()
      myotherlist = :erlang.make_ref() |> inspect()

      ["one", "two", "three"]
      |> Enum.each(fn el ->
        client |> :eredis.q(["RPUSH", mylist, el])
      end)

      {:ok, val} = client |> :eredis.q(["RPOPLPUSH", mylist, myotherlist])
      assert val === "three"

      {:ok, val} = client |> :eredis.q(["LRANGE", mylist, 0, -1])
      assert val === ["one", "two"]

      {:ok, val} = client |> :eredis.q(["LRANGE", myotherlist, 0, -1])
      assert val === ["three"]

      {:ok, val} = client |> :eredis.q(["RPOPLPUSH", unknown_list, myotherlist])
      assert val === :undefined

      {:ok, val} = client |> :eredis.q(["LRANGE", myotherlist, 0, -1])
      assert val === ["three"]
    end

    test "LTRIM", %{client: client} do
      mylist = :erlang.make_ref() |> inspect()

      ["one", "two", "three"]
      |> Enum.each(fn el ->
        client |> :eredis.q(["RPUSH", mylist, el])
      end)

      {:ok, val} = client |> :eredis.q(["LTRIM", mylist, 1, -1])
      assert val === "OK"

      {:ok, val} = client |> :eredis.q(["LRANGE", mylist, 0, -1])
      assert val === ["two", "three"]
    end

    test "LINDEX", %{client: client} do
      mylist = :erlang.make_ref() |> inspect()

      client |> :eredis.q(["LPUSH", mylist, "World"])
      client |> :eredis.q(["LPUSH", mylist, "Hello"])

      {:ok, val} = client |> :eredis.q(["LINDEX", mylist, 0])
      assert val === "Hello"

      {:ok, val} = client |> :eredis.q(["LINDEX", mylist, -1])
      assert val === "World"

      {:ok, val} = client |> :eredis.q(["LINDEX", mylist, 2])
      assert val === :undefined
    end

    test "LSET", %{client: client} do
      mylist = :erlang.make_ref() |> inspect()

      ["one", "two", "three"]
      |> Enum.each(fn el ->
        client |> :eredis.q(["RPUSH", mylist, el])
      end)

      client |> :eredis.q(["LSET", mylist, 0, "four"])
      {:ok, val} = client |> :eredis.q(["LSET", mylist, -2, "five"])
      assert val === "OK"

      {:ok, val} = client |> :eredis.q(["LRANGE", mylist, 0, -1])
      assert val === ["four", "five", "three"]

      {:error, val} = client |> :eredis.q(["LSET", mylist, 200, "seven"])
      assert val === "ERR index out of range"
    end

    ##
    # SETS
    ##
    test "SADD, SCARD, SISMEMBER & SMEMBERS", %{client: client} do
      myset = :erlang.make_ref() |> inspect()
      unknown_set = :erlang.make_ref() |> inspect()

      {:ok, val} = client |> :eredis.q(["SADD", myset, "Hello"])
      assert val === "1"

      {:ok, val} = client |> :eredis.q(["SADD", myset, "World"])
      assert val === "1"

      {:ok, val} = client |> :eredis.q(["SADD", myset, "World"])
      assert val === "0"

      {:ok, val} = client |> :eredis.q(["SMEMBERS", myset])
      assert val |> Enum.sort() === ["Hello", "World"] |> Enum.sort()

      {:ok, val} = client |> :eredis.q(["SISMEMBER", myset, "World"])
      assert val === "1"

      {:ok, val} = client |> :eredis.q(["SISMEMBER", myset, "something"])
      assert val === "0"

      {:ok, val} = client |> :eredis.q(["SMEMBERS", unknown_set])
      assert val === []

      {:ok, val} = client |> :eredis.q(["SCARD", myset])
      assert val === "2"

      {:ok, val} = client |> :eredis.q(["SCARD", unknown_set])
      assert val === "0"

      {:ok, val} = client |> :eredis.q(["SISMEMBER", unknown_set, "something"])
      assert val === "0"

      full_list = ["a", "b", "c", "d"]
      _full_set = full_list |> MapSet.new()
      new_set = :erlang.make_ref() |> inspect()
      {:ok, val} = client |> :eredis.q(["SADD", new_set] ++ full_list)
      assert val === "4"
    end

    test "SMISMEMBER", %{client: client} do
      key = :erlang.make_ref() |> inspect()
      val1 = :erlang.make_ref() |> inspect()
      val2 = :erlang.make_ref() |> inspect()

      {:ok, val} = client |> :eredis.q(["SADD", key, val1])
      assert val === "1"

      {:ok, val} = client |> :eredis.q(["SMISMEMBER", key, val1, val2])
      assert val === ["1", "0"]
    end

    test "SUNION", %{client: client} do
      key1 = :erlang.make_ref() |> inspect()
      key2 = :erlang.make_ref() |> inspect()
      key3 = :erlang.make_ref() |> inspect()

      client |> :eredis.q(["SADD", key1] ++ ["a", "b", "c", "d"])

      client |> :eredis.q(["SADD", key2, "c"])

      client |> :eredis.q(["SADD", key3, "a"])
      client |> :eredis.q(["SADD", key3, "c"])
      client |> :eredis.q(["SADD", key3, "e"])

      unknown_key = :erlang.make_ref() |> inspect()
      {:ok, val} = client |> :eredis.q(["SUNION", key1, key2, key3, unknown_key])
      assert val |> Enum.sort() === ["a", "b", "c", "d", "e"] |> Enum.sort()
    end

    test "SINTER", %{client: client} do
      key1 = :erlang.make_ref() |> inspect()
      key2 = :erlang.make_ref() |> inspect()
      key3 = :erlang.make_ref() |> inspect()

      client |> :eredis.q(["SADD", key1] ++ ["a", "b", "c", "d"])

      client |> :eredis.q(["SADD", key2, "c"])

      client |> :eredis.q(["SADD", key3, "a"])
      client |> :eredis.q(["SADD", key3, "c"])
      client |> :eredis.q(["SADD", key3, "e"])

      {:ok, val} = client |> :eredis.q(["SINTER", key1, key2, key3])
      assert val === ["c"]

      unknown_set = :erlang.make_ref() |> inspect()
      {:ok, val} = client |> :eredis.q(["SINTER", unknown_set, key2, key3])
      assert val === []
    end

    test "SDIFF", %{client: client} do
      key1 = :erlang.make_ref() |> inspect()
      key2 = :erlang.make_ref() |> inspect()
      key3 = :erlang.make_ref() |> inspect()

      client |> :eredis.q(["SADD", key1] ++ ["a", "b", "c", "d"])

      client |> :eredis.q(["SADD", key2, "c"])

      client |> :eredis.q(["SADD", key3, "a"])
      client |> :eredis.q(["SADD", key3, "c"])
      client |> :eredis.q(["SADD", key3, "e"])

      unknown_key = :erlang.make_ref() |> inspect()
      {:ok, val} = client |> :eredis.q(["SDIFF", key1, key2, key3, unknown_key])
      assert val |> Enum.sort() === ["b", "d"] |> Enum.sort()
    end

    test "SRANDMEMBER", %{client: client} do
      key1 = :erlang.make_ref() |> inspect()
      unknown_set = :erlang.make_ref() |> inspect()

      client |> :eredis.q(["SADD", key1] ++ ["a", "b", "c", "d"])

      {:ok, val} = client |> :eredis.q(["SRANDMEMBER", key1])
      assert ["a", "b", "c", "d"] |> MapSet.new() |> MapSet.member?(val)

      {:ok, val} = client |> :eredis.q(["SRANDMEMBER", unknown_set])
      assert val === :undefined
    end

    test "SMOVE", %{client: client} do
      set1 = :erlang.make_ref() |> inspect()
      set2 = :erlang.make_ref() |> inspect()
      unknown_set = :erlang.make_ref() |> inspect()

      client |> :eredis.q(["SADD", set1, "a"])
      client |> :eredis.q(["SADD", set1, "b"])

      {:ok, val} = client |> :eredis.q(["SMOVE", set1, set2, "a"])
      assert val === "1"

      {:ok, val} = client |> :eredis.q(["SISMEMBER", set1, "a"])
      assert val === "0"
      {:ok, val} = client |> :eredis.q(["SISMEMBER", set2, "a"])
      assert val === "1"

      {:ok, val} = client |> :eredis.q(["SCARD", set1])
      assert val === "1"

      {:ok, val} = client |> :eredis.q(["SCARD", set2])
      assert val === "1"

      {:ok, val} = client |> :eredis.q(["SMOVE", set1, set2, "b"])
      assert val === "1"

      {:ok, val} = client |> :eredis.q(["SCARD", set1])
      assert val === "0"

      {:ok, val} = client |> :eredis.q(["EXISTS", "set1"])
      assert val === "0"

      {:ok, val} = client |> :eredis.q(["SMOVE", unknown_set, set2, "a"])
      assert val === "0"

    end

    test "SREM", %{client: client} do
      key1 = :erlang.make_ref() |> inspect()
      unknown_set = :erlang.make_ref() |> inspect()

      full_list = ["a", "b", "c", "d"]
      client |> :eredis.q(["SADD", key1] ++ full_list)

      {:ok, val} = client |> :eredis.q(["SREM", key1, "a", "d", "e"])
      assert val === "2"

      {:ok, val} = client |> :eredis.q(["SREM", unknown_set, "a", "d", "e"])
      assert val === "0"

      {:ok, val} = client |> :eredis.q(["SREM", key1] ++ full_list)
      assert val === "2"

      {:ok, val} = client |> :eredis.q(["SREM", key1] ++ full_list)
      assert val === "0"

      {:ok, val} = client |> :eredis.q(["SREM", "key1"] ++ full_list)
      assert val === "0"
      {:ok, val} = client |> :eredis.q(["EXISTS", "key1"])
      assert val === "0"
    end

    test "SPOP", %{client: client} do
      key1 = :erlang.make_ref() |> inspect()
      key2 = :erlang.make_ref() |> inspect()

      full_list = ["a", "b", "c", "d"]
      full_set = full_list |> MapSet.new()
      client |> :eredis.q(["SADD", key1] ++ full_list)

      {:ok, val} = client |> :eredis.q(["SPOP", key1])
      assert full_set |> MapSet.new() |> MapSet.member?(val)
      val_set = [val] |> MapSet.new()

      {:ok, val} = client |> :eredis.q(["SISMEMBER", key1, val])
      assert val === "0"

      {:ok, members} = client |> :eredis.q(["SMEMBERS", key1])
      assert full_set |> MapSet.difference(val_set) |> Enum.sort() === members |> Enum.sort()

      {:ok, val} = client |> :eredis.q(["SPOP", "unknown_set"])
      assert val === :undefined

      client |> :eredis.q(["SADD", key2, "a"])
      {:ok, val} = client |> :eredis.q(["SPOP", key2])
      assert val === "a"

      # SantoshTODO
      # val = client |> :eredis.q(["EXISTS", key2])
      # assert val === "0"
    end

    test "SINTERSTORE", %{client: client} do
      key1 = :erlang.make_ref() |> inspect()
      key2 = :erlang.make_ref() |> inspect()
      key3 = :erlang.make_ref() |> inspect()
      key4 = :erlang.make_ref() |> inspect()

      full_list = ["a", "b", "c", "d"]
      _full_set = full_list |> MapSet.new()
      client |> :eredis.q(["SADD", key1] ++ full_list)

      client |> :eredis.q(["SADD", key2, "c"])

      client |> :eredis.q(["SADD", key3, "a", "c", "e"])

      {:ok, val} = client |> :eredis.q(["SINTERSTORE", key4, key1, key2, key3])
      assert val === "1"

      {:ok, val} = client |> :eredis.q(["SMEMBERS", key4])
      assert val === ["c"]

      # SantoshTODO
      # Overwrites an existing key
      # client |> :eredis.q(["SET", "mykey", "hello"])
      # client |> :eredis.q(["SINTERSTORE", "mykey", "key1", "key2", "key3"])
      # val = client |> :eredis.q(["SMEMBERS", "mykey"])
      # assert val === ["c"]

      # Deletes a key when storing an empty set
      # val = client |> :eredis.q(["SINTERSTORE", "mykey", "unknown_set", "unknown_set"])
      # assert val === "0"
      # val = client |> :eredis.q(["EXISTS", "mykey"])
      # assert val === "0"
    end

    test "SUNIONSTORE", %{client: client} do
      key1 = :erlang.make_ref() |> inspect()
      key2 = :erlang.make_ref() |> inspect()
      key3 = :erlang.make_ref() |> inspect()
      key4 = :erlang.make_ref() |> inspect()

      full_list = ["a", "b", "c", "d"]
      _full_set = full_list |> MapSet.new()
      client |> :eredis.q(["SADD", key1] ++ full_list)

      client |> :eredis.q(["SADD", key2, "c"])

      client |> :eredis.q(["SADD", key3, "a", "c", "e"])

      {:ok, val} = client |> :eredis.q(["SUNIONSTORE", key4, key1, key2, key3])
      assert val === "5"

      {:ok, val} = client |> :eredis.q(["SMEMBERS", key4])
      assert val |> Enum.sort() === ["a", "b", "c", "d", "e"] |> Enum.sort()

      # SantoshTODO
      # Overwrites an existing key
      # client |> :eredis.q(["SET", "mykey", "hello"])
      # client |> :eredis.q(["SUNIONSTORE", "mykey", "key1", "key2", "key3"])
      # val = client |> :eredis.q(["SMEMBERS", "mykey"])
      # assert (val |> Enum.sort) === (["a", "b", "c", "d", "e"] |> Enum.sort)
      #
      # Deletes a key when storing an empty set
      # val = client |> :eredis.q(["SUNIONSTORE", "mykey", "unknown_set", "unknown_set"])
      # assert val === "0"
      # val = client |> :eredis.q(["EXISTS", "mykey"])
      # assert val === "0"
    end

    test "SDIFFSTORE", %{client: client} do
      key1 = :erlang.make_ref() |> inspect()
      key2 = :erlang.make_ref() |> inspect()
      key3 = :erlang.make_ref() |> inspect()

      client |> :eredis.q(["SADD", key1] ++ ["a", "b", "c", "d"])

      client |> :eredis.q(["SADD", key2, "c"])

      client |> :eredis.q(["SADD", key3, "a"])
      client |> :eredis.q(["SADD", key3, "c"])
      client |> :eredis.q(["SADD", key3, "e"])

      key = :erlang.make_ref() |> inspect()
      {:ok, val} = client |> :eredis.q(["SDIFFSTORE", key, key1, key2, key3])
      assert val === "2"

      {:ok, val} = client |> :eredis.q(["SMEMBERS", key])
      assert val |> Enum.sort() === ["b", "d"] |> Enum.sort()

      # SantoshTODO
      # #Overwrites an existing key
      # client |> :eredis.q(["SET", "mykey", "hello"])
      # client |> :eredis.q(["SDIFFSTORE", "mykey", "key1", "key2", "key3"])
      # val = client |> :eredis.q(["SMEMBERS", "mykey"])
      # assert (val |> Enum.sort) === (["b", "d"] |> Enum.sort)
      #
      # Deletes a key when storing an empty set
      # val = client |> :eredis.q(["SDIFFSTORE", "mykey", "key1", "key1"])
      # assert val === "0"
      # val = client |> :eredis.q(["EXISTS", "mykey"])
      # assert val === "0"
    end

    test "HSET, HGET, HLEN, HEXISTS, HKEYS, HVALS, HDEL, HGETALL, HSTRLEN, HSETNX, HINCRBY", %{
      client: client
    } do
      my_hash = :erlang.make_ref() |> inspect()
      unknown_hash = :erlang.make_ref() |> inspect()

      {:ok, val} = client |> :eredis.q(["HSET", my_hash, "name", "john"])
      assert val === "1"
      {:ok, val} = client |> :eredis.q(["HSET", my_hash, "name", "john"])
      assert val === "0"
      # Adding a new key to an existing hash
      client |> :eredis.q(["HSET", my_hash, "age", "30"])
      assert val === "0"

      {:ok, val} = client |> :eredis.q(["HLEN", my_hash])
      assert val === "2"

      {:ok, val} = client |> :eredis.q(["HGETALL", my_hash])
      assert val |> Enum.sort() === ["name", "john", "age", "30"] |> Enum.sort()

      {:ok, val} = client |> :eredis.q(["HGET", my_hash, "name"])
      assert val === "john"
      {:ok, val} = client |> :eredis.q(["HGET", my_hash, "unknown_field"])
      assert val === :undefined

      {:ok, val} = client |> :eredis.q(["HKEYS", my_hash])
      assert val |> Enum.sort() === ["name", "age"] |> Enum.sort()

      {:ok, val} = client |> :eredis.q(["HEXISTS", my_hash, "name"])
      assert val === "1"
      {:ok, val} = client |> :eredis.q(["HEXISTS", my_hash, "unknown_field"])
      assert val === "0"
      {:ok, val} = client |> :eredis.q(["HEXISTS", unknown_hash, "unknown_field"])
      assert val === "0"

      {:ok, val} = client |> :eredis.q(["HKEYS", unknown_hash])
      assert val === []

      {:ok, val} = client |> :eredis.q(["HVALS", my_hash])
      assert val |> Enum.sort() === ["john", "30"] |> Enum.sort()
      {:ok, val} = client |> :eredis.q(["HVALS", unknown_hash])
      assert val === []

      {:ok, val} =
        client |> :eredis.q(["HMSET", my_hash, "city", "SF", "state", "CA", "name", "john"])

      assert val === "OK"
      {:ok, val} = client |> :eredis.q(["HGET", my_hash, "city"])
      assert val === "SF"

      {:ok, val} = client |> :eredis.q(["HMGET", my_hash, "city", "state", "name", "unknown_field"])
      assert val === ["SF", "CA", "john", :undefined]

      {:ok, val} = client |> :eredis.q(["HMGET", unknown_hash, "city", "state"])
      assert val === [:undefined, :undefined]

      {:ok, val} = client |> :eredis.q(["HSTRLEN", my_hash, "name"])
      assert val === "john" |> String.length() |> Integer.to_string()
      {:ok, val} = client |> :eredis.q(["HSTRLEN", unknown_hash, "name"])
      assert val === "0"
      {:ok, val} = client |> :eredis.q(["HSTRLEN", my_hash, "unknown_set"])
      assert val === "0"

      client |> :eredis.q(["HSET", my_hash, "city", "SF"])
      {:ok, val} = client |> :eredis.q(["HDEL", my_hash, "city", "unknown_field", "name"])
      assert val === "2"

      {:ok, val} = client |> :eredis.q(["HSETNX", my_hash, "city", "SF"])
      assert val === "1"
      {:ok, val} = client |> :eredis.q(["HSETNX", my_hash, "city", "SF"])
      assert val === "0"

      {:ok, val} = client |> :eredis.q(["HINCRBY", my_hash, "counter", 3])
      assert val === "3"
      {:ok, val} = client |> :eredis.q(["HINCRBY", my_hash, "counter", 300])
      assert val === "303"
      {:ok, val} = client |> :eredis.q(["HINCRBY", my_hash, "counter", -600])
      assert val === "-297"
      # SantoshTODO
      # val = client |> :eredis.q(["HDEL", "myhash", "city", "unknown_field", "name", "age"])
      # assert val === "1"
      # val = client |> :eredis.q(["EXISTS", "myhash"])
      # assert val === "0"
    end

    @tag slow: true, skip: true
    test "EXPIRE", %{client: client} do
      {:ok, val} = client |> :eredis.q(["SET", "mykey", "hello"])
      assert val === "OK"

      {:ok, val} = client |> :eredis.q(["EXPIRE", "mykey", 1])
      assert val === "1"

      {:ok, val} = client |> :eredis.q(["TTL", "mykey"])
      assert val === "1"

      :timer.sleep(1_200)
      {:ok, val} = client |> :eredis.q(["TTL", "mykey"])
      assert val === "-2"

      {:ok, val} = client |> :eredis.q(["GET", "mykey"])
      assert val === :undefined
    end

    @tag slow: true, skip: true
    test "PERSIST", %{client: client} do
      {:ok, val} = client |> :eredis.q(["SET", "mykey", "hello"])
      assert val === "OK"

      {:ok, val} = client |> :eredis.q(["EXPIRE", "mykey", 1])
      assert val === "1"

      {:ok, val} = client |> :eredis.q(["PERSIST", "mykey"])
      assert val === "1"

      {:ok, val} = client |> :eredis.q(["TTL", "mykey"])
      assert val === "-1"

      :timer.sleep(1_200)
      {:ok, val} = client |> :eredis.q(["GET", "mykey"])
      assert val === "hello"

      {:ok, val} = client |> :eredis.q(["PERSIST", "unknown_key"])
      assert val === "0"

      {:ok, val} = client |> :eredis.q(["TTL", "unknown_key"])
      assert val === "-2"
    end

    test "flushall", %{client: client} do
      client |> :eredis.q(["SET", "A", "1"])
      { :ok, db_sz} = client |> :eredis.q(["DBSIZE"])
      db_sz = db_sz |> String.to_integer()
      assert db_sz > 0

      {:ok, val} = client |> :eredis.q(["FLUSHALL"])
      assert val === "OK"
      {:ok, new_db_sz} = client |> :eredis.q(["DBSIZE"])
      new_db_sz = new_db_sz |> String.to_integer()
      assert new_db_sz === 0
      # assert val === (prev_db_size + 2)
    end
  end
end
