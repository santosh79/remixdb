defmodule RemixdbTest do
  defmodule Server do
    use ExUnit.Case

    setup_all context do
      Remixdb.Server.start
      :ok
    end

    @tag :current
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
      client |> Exredis.query ["SET", "A", "1"]
      client |> Exredis.query ["SET", "B", "2"]
      val = client |> Exredis.query(["DBSIZE"]) |> String.to_integer
      assert val === (prev_db_size + 2)
      client |> Exredis.stop
    end

    @tag :skip
    test "flushall" do
      client = Exredis.start_using_connection_string("redis://127.0.0.1:6379")
      client |> Exredis.query ["SET", "A", "1"]
      db_sz = client |> Exredis.query(["DBSIZE"]) |> String.to_integer
      assert db_sz > 0

      client |> Exredis.query ["FLUSHALL"]
      new_db_sz = client |> Exredis.query(["DBSIZE"]) |> String.to_integer
      assert new_db_sz === 0
      # assert val === (prev_db_size + 2)
      client |> Exredis.stop
    end
  end
end

