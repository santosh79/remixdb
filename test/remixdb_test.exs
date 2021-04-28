defmodule RemixdbTest do
  defmodule Server do
    use ExUnit.Case

    setup_all _context do
      client = Exredis.start_using_connection_string("redis://127.0.0.1:6379")
      :timer.sleep 1_000
      {:ok, %{client: client}}
    end

    setup context do
      %{client: client} = context
      client |> Exredis.query(["FLUSHALL"])
      {:ok, %{client: client}}
    end

    test "exists", %{client: client} do
      non_exist_key = UUID.uuid4
      key = UUID.uuid4

      val = client |> Exredis.query(["EXISTS", non_exist_key])
      assert val === "0"

      vv = UUID.uuid4
      client |> Exredis.query(["SET", key, vv])
      val = client |> Exredis.query(["EXISTS", key])
      assert val === "1"
    end

    test "set and get", %{client: client} do
      key = UUID.uuid4
      vv = UUID.uuid4
      client |> Exredis.query(["SET", key, vv])
      val = client |> Exredis.query(["GET", key])
      assert val === vv
    end

    test "getset", %{client: client} do
      key = UUID.uuid4
      vv = UUID.uuid4

      val = client |> Exredis.query(["GETSET", key, vv])
      assert val === :undefined

      vv_n = UUID.uuid4
      val = client |> Exredis.query(["GETSET", key, vv_n])
      assert val === vv

      val = client |> Exredis.query(["GET", key])
      assert val === vv_n
    end

    test "get non-existent key", %{client: client} do
      non_exist_key = UUID.uuid4
      val = client |> Exredis.query(["GET", non_exist_key])
      assert val === :undefined
    end

    test "dbsize", %{client: client} do
      prev_db_size = client |> Exredis.query(["DBSIZE"]) |> String.to_integer
      1..1_000 |> Enum.each(fn(_x) ->
        val = key = UUID.uuid4
        client |> Exredis.query(["SET", key, val])
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
      key = UUID.uuid4
      vv = UUID.uuid4

      val = client |> Exredis.query(["APPEND", key, vv])
      assert val === (vv |> String.length) |> Integer.to_string

      val = client |> Exredis.query(["GET", key])
      assert val === vv
    end

    test "INCR", %{client: client} do
      counter = UUID.uuid4
      val = client |> Exredis.query(["INCR", counter])
      assert val === "1"

      val = client |> Exredis.query(["INCR", counter])
      assert val === "2"
    end

    test "INCRBY", %{client: client} do
      counter = UUID.uuid4
      val = client |> Exredis.query(["INCRBY", counter, 5])
      assert val === "5"

      val = client |> Exredis.query(["INCRBY", counter, 10])
      assert val === "15"
    end

    test "DECR", %{client: client} do
      counter = UUID.uuid4
      val = client |> Exredis.query(["DECR", counter])
      assert val === "-1"

      client |> Exredis.query(["INCR", counter])
      client |> Exredis.query(["INCR", counter])
      val = client |> Exredis.query(["DECR", counter])
      assert val === "0"
    end

    test "DECRBY", %{client: client} do
      counter = UUID.uuid4
      val = client |> Exredis.query(["DECRBY", counter, 5])
      assert val === "-5"

      client |> Exredis.query(["INCRBY", counter, 10])
      val = client |> Exredis.query(["DECRBY", counter, 5])
      assert val === "0"
    end

    test "append - existing key", %{client: client} do
      mykey = UUID.uuid4
      client |> Exredis.query(["SET", mykey, "hello"])
      val = client |> Exredis.query(["APPEND", mykey, " world"])
      assert val === "11"

      val = client |> Exredis.query(["GET", mykey])
      assert val === "hello world"
    end

    # @tag slow: true
    @tag skip: true
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

    @tag current: true
    test "RENAME", %{client: client} do
      kk = UUID.uuid4
      vv = UUID.uuid4

      val = client |> Exredis.query(["SET", kk, vv])
      assert val === "OK"

      new_kk = UUID.uuid4
      val = client |> Exredis.query(["RENAME", kk, new_kk])
      assert val === "OK"

      val = client |> Exredis.query(["GET", kk])
      assert val === :undefined

      val = client |> Exredis.query(["GET", new_kk])
      assert val === vv


      unknown_key = UUID.uuid4
      val = client |> Exredis.query(["RENAME", unknown_key, UUID.uuid4])
      assert val === "ERR no such key"
    end

    @tag skip: true
    test "RENAMENX", %{client: client} do
      client |> Exredis.query(["SET", "mykey", "hello"])
      val = client |> Exredis.query(["RENAMENX", "mykey", "foo"])
      assert val === "1"

      client |> Exredis.query(["SET", "mykey", "hello"])
      val = client |> Exredis.query(["RENAMENX", "foo", "mykey"])
      assert val === "0"

      val = client |> Exredis.query(["RENAMENX", "unknown_key", "something"])
      assert val === "ERR no such key"
    end

    ##
    # LISTS
    ##
    test "RPOP & LPUSH", %{client: client} do
      val = client |> Exredis.query(["RPUSH", "mylist", "three", "four", "five", "six"])
      assert val === "4"

      client |> Exredis.query(["LPUSH", "mylist", "two"])
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

      val = client |> Exredis.query(["RPOP", "mylist"])
      assert val === :undefined
    end

    test "LRANGE", %{client: client} do
      mylist = UUID.uuid4
      client |> Exredis.query(["RPUSH", mylist, "one"])
      client |> Exredis.query(["RPUSH", mylist, "two"])
      client |> Exredis.query(["RPUSH", mylist, "three"])

      val = client |> Exredis.query(["LRANGE", mylist, 0, -1])
      assert val === ["one", "two", "three"]

      val = client |> Exredis.query(["LRANGE", mylist, 0, 0])
      assert val === ["one"]

      val = client |> Exredis.query(["LRANGE", mylist, -3, -2])
      assert val === ["one", "two"]

      val = client |> Exredis.query(["LRANGE", mylist, -100, 100])
      assert val === ["one", "two", "three"]

      val = client |> Exredis.query(["LRANGE", mylist, 5, 10])
      assert val === []

      val = client |> Exredis.query(["LRANGE", mylist, -100, 0])
      assert val === ["one"]

      unknown_list = UUID.uuid4
      val = client |> Exredis.query(["LRANGE", unknown_list, 5, 10])
      assert val === []
    end

    test "LPUSHX & RPUSHX", %{client: client} do
      mylist = UUID.uuid4
      unknown_list = UUID.uuid4

      val = client |> Exredis.query(["LPUSH", mylist, "world"])
      assert val === "1"

      val = client |> Exredis.query(["LPUSHX", mylist, "Hello"])
      assert val === "2"

      val = client |> Exredis.query(["RPUSHX", mylist, "There"])
      assert val === "3"

      val = client |> Exredis.query(["LPUSHX", unknown_list, "Hello"])
      assert val === "0"

      val = client |> Exredis.query(["RPUSHX", unknown_list, "Hello"])
      assert val === "0"

      val = client |> Exredis.query(["LLEN", mylist])
      assert val === "3"

      val = client |> Exredis.query(["LLEN", unknown_list])
      assert val === "0"

      val = client |> Exredis.query(["EXISTS", unknown_list])
      assert val === "0"
    end

    test "LPOP, RPUSH & LLEN", %{client: client} do
      mylist = UUID.uuid4
      unknown_list = UUID.uuid4

      val = client |> Exredis.query(["LLEN", mylist])
      assert val === "0"

      val = client |> Exredis.query(["RPUSH", mylist, "one",  "two"])
      assert val === "2"
      val = client |> Exredis.query(["RPUSH", mylist, "three"])
      assert val === "3"

      val = client |> Exredis.query(["LLEN", mylist])
      assert val === "3"

      val = client |> Exredis.query(["LPOP", mylist])
      assert val === "one"

      client |> Exredis.query(["LPOP", mylist])
      client |> Exredis.query(["LPOP", mylist])
      val = client |> Exredis.query(["LPOP", mylist])
      assert val === :undefined

      # SantoshTODO
      # val = client |> Exredis.query(["EXISTS", mylist])
      # assert val === "0"

      val = client |> Exredis.query(["LPOP", unknown_list])
      assert val === :undefined
    end

    test "RPOPLPUSH", %{client: client} do
      mylist = UUID.uuid4
      unknown_list = UUID.uuid4
      myotherlist = UUID.uuid4

      ["one", "two", "three"] |> Enum.each(fn(el) ->
        client |> Exredis.query(["RPUSH", mylist, el])
      end)

      val = client |> Exredis.query(["RPOPLPUSH", mylist, myotherlist])
      assert val === "three"

      val = client |> Exredis.query(["LRANGE", mylist, 0, -1])
      assert val === ["one", "two"]

      val = client |> Exredis.query(["LRANGE", myotherlist, 0, -1])
      assert val === ["three"]

      val = client |> Exredis.query(["RPOPLPUSH", unknown_list, myotherlist])
      assert val === :undefined

      val = client |> Exredis.query(["LRANGE", myotherlist, 0, -1])
      assert val === ["three"]
    end

    test "LTRIM", %{client: client} do
      mylist = UUID.uuid4

      ["one", "two", "three"] |> Enum.each(fn(el) ->
        client |> Exredis.query(["RPUSH", mylist, el])
      end)

      val = client |> Exredis.query(["LTRIM", mylist, 1, -1])
      assert val === "OK"

      val = client |> Exredis.query(["LRANGE", mylist, 0, -1])
      assert val === ["two", "three"]
    end

    test "LINDEX", %{client: client} do
      mylist = UUID.uuid4

      client |> Exredis.query(["LPUSH", mylist, "World"])
      client |> Exredis.query(["LPUSH", mylist, "Hello"])

      val = client |> Exredis.query(["LINDEX", mylist, 0])
      assert val === "Hello"

      val = client |> Exredis.query(["LINDEX", mylist, -1])
      assert val === "World"

      val = client |> Exredis.query(["LINDEX", mylist, 2])
      assert val === :undefined
    end

    test "LSET", %{client: client} do
      mylist = UUID.uuid4

      ["one", "two", "three"] |> Enum.each(fn(el) ->
        client |> Exredis.query(["RPUSH", mylist, el])
      end)

      client |> Exredis.query(["LSET", mylist, 0, "four"])
      val = client |> Exredis.query(["LSET", mylist, -2, "five"])
      assert val === "OK"

      val = client |> Exredis.query(["LRANGE", mylist, 0, -1])
      assert val === ["four", "five", "three"]

      val = client |> Exredis.query(["LSET", mylist, 200, "seven"])
      assert val === "ERR index out of range"
    end

    ##
    # SETS
    ##
    test "SADD, SCARD, SISMEMBER & SMEMBERS", %{client: client} do
      myset = UUID.uuid4
      unknown_set = UUID.uuid4
      
      val = client |> Exredis.query(["SADD", myset, "Hello"])
      assert val === "1"

      val = client |> Exredis.query(["SADD", myset, "World"])
      assert val === "1"

      val = client |> Exredis.query(["SADD", myset, "World"])
      assert val === "0"

      val = client |> Exredis.query(["SMEMBERS", myset])
      assert (val |> Enum.sort) === (["Hello", "World"] |> Enum.sort)

      val = client |> Exredis.query(["SISMEMBER", myset, "World"])
      assert val === "1"

      val = client |> Exredis.query(["SISMEMBER", myset, "something"])
      assert val === "0"

      val = client |> Exredis.query(["SMEMBERS", unknown_set])
      assert val === []

      val = client |> Exredis.query(["SCARD", myset])
      assert val === "2"

      val = client |> Exredis.query(["SCARD", unknown_set])
      assert val === "0"

      val = client |> Exredis.query(["SISMEMBER", unknown_set, "something"])
      assert val === "0"

      full_list =  ["a", "b", "c", "d"] 
      _full_set = full_list |> MapSet.new
      new_set = UUID.uuid4
      val = client |> Exredis.query(["SADD", new_set] ++ full_list)
      assert val === "4"
    end

    test "SMISMEMBER", %{client: client} do
      key = UUID.uuid4
      val1 = UUID.uuid4
      val2 = UUID.uuid4

      val = client |> Exredis.query(["SADD", key, val1])
      assert val === "1"

      val = client |> Exredis.query(["SMISMEMBER", key, val1, val2])
      assert val === ["1", "0"]
    end

    test "SUNION", %{client: client} do
      key1 = UUID.uuid4
      key2 = UUID.uuid4
      key3 = UUID.uuid4

      client |> Exredis.query(["SADD", key1] ++ ["a", "b", "c", "d"])

      client |> Exredis.query(["SADD", key2, "c"])

      client |> Exredis.query(["SADD", key3, "a"])
      client |> Exredis.query(["SADD", key3, "c"])
      client |> Exredis.query(["SADD", key3, "e"])

      unknown_key = UUID.uuid4
      val = client |> Exredis.query(["SUNION", key1, key2, key3, unknown_key])
      assert (val |> Enum.sort) === (["a", "b", "c", "d", "e"] |> Enum.sort)
    end

    test "SINTER", %{client: client} do
      key1 = UUID.uuid4
      key2 = UUID.uuid4
      key3 = UUID.uuid4

      client |> Exredis.query(["SADD", key1] ++ ["a", "b", "c", "d"])

      client |> Exredis.query(["SADD", key2, "c"])

      client |> Exredis.query(["SADD", key3, "a"])
      client |> Exredis.query(["SADD", key3, "c"])
      client |> Exredis.query(["SADD", key3, "e"])

      val = client |> Exredis.query(["SINTER", key1, key2, key3])
      assert val === ["c"]

      unknown_set = UUID.uuid4
      val = client |> Exredis.query(["SINTER", unknown_set, key2, key3])
      assert val === []
    end

    test "SDIFF", %{client: client} do
      key1 = UUID.uuid4
      key2 = UUID.uuid4
      key3 = UUID.uuid4

      client |> Exredis.query(["SADD", key1] ++ ["a", "b", "c", "d"])

      client |> Exredis.query(["SADD", key2, "c"])

      client |> Exredis.query(["SADD", key3, "a"])
      client |> Exredis.query(["SADD", key3, "c"])
      client |> Exredis.query(["SADD", key3, "e"])

      unknown_key = UUID.uuid4
      val = client |> Exredis.query(["SDIFF", key1, key2, key3, unknown_key])
      assert (val |> Enum.sort) === (["b", "d"] |> Enum.sort)
    end

    test "SRANDMEMBER", %{client: client} do
      key1 = UUID.uuid4
      unknown_set = UUID.uuid4

      client |> Exredis.query(["SADD", key1] ++ ["a", "b", "c", "d"])

      val = client |> Exredis.query(["SRANDMEMBER", key1])
      assert (["a", "b", "c", "d"] |> MapSet.new |> MapSet.member?(val))

      val = client |> Exredis.query(["SRANDMEMBER", unknown_set])
      assert val === :undefined
    end

    test "SMOVE", %{client: client} do
      set1 = UUID.uuid4
      set2 = UUID.uuid4

      client |> Exredis.query(["SADD", set1, "a"])
      client |> Exredis.query(["SADD", set1, "b"])

      val = client |> Exredis.query(["SMOVE", set1, set2, "a"])
      assert val === "1"

      val = client |> Exredis.query(["SISMEMBER", set1, "a"])
      assert val === "0"
      val = client |> Exredis.query(["SISMEMBER", set2, "a"])
      assert val === "1"

      val = client |> Exredis.query(["SCARD", set1])
      assert val === "1"

      val = client |> Exredis.query(["SCARD", set2])
      assert val === "1"

      # SantoshTODO
      # val = client |> Exredis.query(["EXISTS", "key2"])
      # assert val === "0"

      # val = client |> Exredis.query(["SMOVE", "key1", "key2", "a"])
      # assert val === "1"

      # val = client |> Exredis.query(["EXISTS", "key2"])
      # assert val === "1"

      # val = client |> Exredis.query(["SMOVE", "key1", "key2", "a"])
      # assert val === "0"

      # val = client |> Exredis.query(["SMOVE", "unknown_set", "key2", "a"])
      # assert val === "0"

      # val = client |> Exredis.query(["EXISTS", "key1"])
      # assert val === "0"
    end

    test "SREM", %{client: client} do
      key1 = UUID.uuid4
      unknown_set = UUID.uuid4

      full_list = ["a", "b", "c", "d"]
      client |> Exredis.query(["SADD", key1] ++ full_list)

      val = client |> Exredis.query(["SREM", key1, "a", "d", "e"])
      assert val === "2"

      val = client |> Exredis.query(["SREM", unknown_set, "a", "d", "e"])
      assert val === "0"

      val = client |> Exredis.query(["SREM", key1] ++ full_list)
      assert val === "2"

      val = client |> Exredis.query(["SREM", key1] ++ full_list)
      assert val === "0"

      # SantoshTODO
      # val = client |> Exredis.query(["SREM", "key1"] ++ full_list)
      # val = client |> Exredis.query(["EXISTS", "key1"])
      # assert val === "0"
    end

    test "SPOP", %{client: client} do
      key1 = UUID.uuid4()
      key2 = UUID.uuid4()

      full_list = ["a", "b", "c", "d"]
      full_set =  full_list |> MapSet.new
      client |> Exredis.query(["SADD", key1] ++ full_list)

      val = client |> Exredis.query(["SPOP", key1])
      assert (full_set |> MapSet.new |> MapSet.member?(val))
      val_set = [val] |> MapSet.new

      val = client |> Exredis.query(["SISMEMBER", key1, val])
      assert val === "0"

      members =  client |> Exredis.query(["SMEMBERS", key1])
      assert (full_set |> MapSet.difference(val_set) |> Enum.sort) === (members |> Enum.sort)

      val = client |> Exredis.query(["SPOP", "unknown_set"])
      assert val === :undefined

      client |> Exredis.query(["SADD", key2, "a"])
      val = client |> Exredis.query(["SPOP", key2])
      assert val === "a"

      # SantoshTODO
      # val = client |> Exredis.query(["EXISTS", key2])
      # assert val === "0"
    end

    test "SINTERSTORE", %{client: client} do
      key1 = UUID.uuid4
      key2 = UUID.uuid4
      key3 = UUID.uuid4
      key4 = UUID.uuid4

      full_list =  ["a", "b", "c", "d"] 
      _full_set = full_list |> MapSet.new
      client |> Exredis.query(["SADD", key1] ++ full_list)

      client |> Exredis.query(["SADD", key2, "c"])

      client |> Exredis.query(["SADD", key3, "a", "c", "e"])

      val = client |> Exredis.query(["SINTERSTORE", key4, key1, key2, key3])
      assert val === "1"

      val = client |> Exredis.query(["SMEMBERS", key4])
      assert val === ["c"]

      # SantoshTODO
      #Overwrites an existing key
      # client |> Exredis.query(["SET", "mykey", "hello"])
      # client |> Exredis.query(["SINTERSTORE", "mykey", "key1", "key2", "key3"])
      # val = client |> Exredis.query(["SMEMBERS", "mykey"])
      # assert val === ["c"]

      # Deletes a key when storing an empty set
      # val = client |> Exredis.query(["SINTERSTORE", "mykey", "unknown_set", "unknown_set"])
      # assert val === "0"
      # val = client |> Exredis.query(["EXISTS", "mykey"])
      # assert val === "0"
    end

    test "SUNIONSTORE", %{client: client} do
      key1 = UUID.uuid4
      key2 = UUID.uuid4
      key3 = UUID.uuid4
      key4 = UUID.uuid4

      full_list =  ["a", "b", "c", "d"] 
      _full_set = full_list |> MapSet.new
      client |> Exredis.query(["SADD", key1] ++ full_list)

      client |> Exredis.query(["SADD", key2, "c"])

      client |> Exredis.query(["SADD", key3, "a", "c", "e"])

      val = client |> Exredis.query(["SUNIONSTORE", key4, key1, key2, key3])
      assert val === "5"

      val = client |> Exredis.query(["SMEMBERS", key4])
      assert (val |> Enum.sort) === (["a", "b", "c", "d", "e"] |> Enum.sort)

      # SantoshTODO
      #Overwrites an existing key
      # client |> Exredis.query(["SET", "mykey", "hello"])
      # client |> Exredis.query(["SUNIONSTORE", "mykey", "key1", "key2", "key3"])
      # val = client |> Exredis.query(["SMEMBERS", "mykey"])
      # assert (val |> Enum.sort) === (["a", "b", "c", "d", "e"] |> Enum.sort)
      #
      # Deletes a key when storing an empty set
      # val = client |> Exredis.query(["SUNIONSTORE", "mykey", "unknown_set", "unknown_set"])
      # assert val === "0"
      # val = client |> Exredis.query(["EXISTS", "mykey"])
      # assert val === "0"
    end

    test "SDIFFSTORE", %{client: client} do
      key1 = UUID.uuid4
      key2 = UUID.uuid4
      key3 = UUID.uuid4

      client |> Exredis.query(["SADD", key1] ++ ["a", "b", "c", "d"])

      client |> Exredis.query(["SADD", key2, "c"])

      client |> Exredis.query(["SADD", key3, "a"])
      client |> Exredis.query(["SADD", key3, "c"])
      client |> Exredis.query(["SADD", key3, "e"])

      key = UUID.uuid4
      val = client |> Exredis.query(["SDIFFSTORE", key, key1, key2, key3])
      assert val === "2"

      val = client |> Exredis.query(["SMEMBERS", key])
      assert (val |> Enum.sort) === (["b", "d"] |> Enum.sort)

      # SantoshTODO
      # #Overwrites an existing key
      # client |> Exredis.query(["SET", "mykey", "hello"])
      # client |> Exredis.query(["SDIFFSTORE", "mykey", "key1", "key2", "key3"])
      # val = client |> Exredis.query(["SMEMBERS", "mykey"])
      # assert (val |> Enum.sort) === (["b", "d"] |> Enum.sort)
      #
      # Deletes a key when storing an empty set
      # val = client |> Exredis.query(["SDIFFSTORE", "mykey", "key1", "key1"])
      # assert val === "0"
      # val = client |> Exredis.query(["EXISTS", "mykey"])
      # assert val === "0"
    end

    test "HSET, HGET, HLEN, HEXISTS, HKEYS, HVALS, HDEL, HGETALL, HSTRLEN, HSETNX, HINCRBY", %{client: client} do
      my_hash = UUID.uuid4
      unknown_hash = UUID.uuid4
      counter= UUID.uuid4

      val = client |> Exredis.query(["HSET", my_hash, "name", "john"])
      assert val === "1"
      val = client |> Exredis.query(["HSET", my_hash, "name", "john"])
      assert val === "0"
      client |> Exredis.query(["HSET", my_hash, "age", "30"])

      val = client |> Exredis.query(["HLEN", my_hash])
      assert val === "2"

      val = client |> Exredis.query(["HGETALL", my_hash])
      assert (val |> Enum.sort) === (["name", "john", "age", "30"] |> Enum.sort)

      val = client |> Exredis.query(["HGET", my_hash, "name"])
      assert val === "john"
      val = client |> Exredis.query(["HGET", my_hash, "unknown_field"])
      assert val === :undefined

      val = client |> Exredis.query(["HKEYS", my_hash])
      assert (val |> Enum.sort) === (["name", "age"] |> Enum.sort)

      val = client |> Exredis.query(["HEXISTS", my_hash, "name"])
      assert val === "1"
      val = client |> Exredis.query(["HEXISTS", my_hash, "unknown_field"])
      assert val === "0"
      val = client |> Exredis.query(["HEXISTS", unknown_hash, "unknown_field"])
      assert val === "0"

      val = client |> Exredis.query(["HKEYS", unknown_hash])
      assert val === []

      val = client |> Exredis.query(["HVALS", my_hash])
      assert (val |> Enum.sort) === (["john", "30"] |> Enum.sort)
      val = client |> Exredis.query(["HVALS", unknown_hash])
      assert val === []

      val = client |> Exredis.query(["HMSET", my_hash, "city", "SF", "state", "CA", "name", "john"])
      assert val === "OK"
      val = client |> Exredis.query(["HGET", my_hash, "city"])
      assert val === "SF"

      val = client |> Exredis.query(["HMGET", my_hash, "city", "state", "name", "unknown_field"])
      assert val === ["SF", "CA", "john", :undefined]

      val = client |> Exredis.query(["HMGET", unknown_hash, "city", "state"])
      assert val === [:undefined, :undefined]

      val = client |> Exredis.query(["HSTRLEN", my_hash, "name"])
      assert val === ("john" |> String.length |> Integer.to_string)
      val = client |> Exredis.query(["HSTRLEN", unknown_hash, "name"])
      assert val === "0"
      val = client |> Exredis.query(["HSTRLEN", my_hash, "unknown_set"])
      assert val === "0"

      client |> Exredis.query(["HSET", my_hash, "city", "SF"])
      val = client |> Exredis.query(["HDEL", my_hash, "city", "unknown_field", "name"])
      assert val === "2"

      val = client |> Exredis.query(["HSETNX", my_hash, "city", "SF"])
      assert val === "1"
      val = client |> Exredis.query(["HSETNX", my_hash, "city", "SF"])
      assert val === "0"

      val = client |> Exredis.query(["HINCRBY", my_hash, "counter", 3])
      assert val === "3"
      val = client |> Exredis.query(["HINCRBY", my_hash, "counter", 300])
      assert val === "303"
      val = client |> Exredis.query(["HINCRBY", my_hash, "counter", -600])
      assert val === "-297"
      # SantoshTODO
      # val = client |> Exredis.query(["HDEL", "myhash", "city", "unknown_field", "name", "age"])
      # assert val === "1"
      # val = client |> Exredis.query(["EXISTS", "myhash"])
      # assert val === "0"
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

