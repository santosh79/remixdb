defmodule Remixdb.Parsers.RedisParser do
  use GenServer

  def start_link(socket) do
    GenServer.start_link(__MODULE__, {:ok, socket}, [])
  end

  def init({:ok, socket}) do
    {:ok, {socket, <<>>}}  # state is now {socket, buffer}
  end

  def read_command(pid) do
    GenServer.call(pid, :read_command, :infinity)
  end

  def handle_call(:read_command, _from, {socket, buffer} = state) do
    case read_new_command(socket, buffer) do
      {:ok, [cmd | args], rest_buffer} ->
        res = parse_command(cmd, args)
        {:reply, {:ok, res}, {socket, rest_buffer}}
      {:error, reason} ->
        {:stop, :normal, {:error, reason}, state}
    end
  end

  defp read_new_command(socket, buffer) do
    {:ok, num_args, buffer} = read_number_args(socket, buffer)
    read_args(socket, num_args, [], buffer)
  end

  defp read_line(socket, buffer) do
    case :binary.match(buffer, "\r\n") do
      {pos, 2} ->
        line = :binary.part(buffer, 0, pos + 2)
        rest = :binary.part(buffer, pos + 2, byte_size(buffer) - pos - 2)
        {:ok, line, rest}
      :nomatch ->
        case :gen_tcp.recv(socket, 0) do
          {:ok, chunk} -> read_line(socket, buffer <> chunk)
          {:error, reason} -> {:error, reason}
        end
    end
  end

  defp read_number_args(socket, buffer) do
    {:ok, data, rest} = read_line(socket, buffer)
    <<?*, raw_num::binary>> = data
    num = to_int(raw_num)
    {:ok, num, rest}
  end

  defp to_int(bin) when is_binary(bin) do
    bin|>
      :binary.part(0, :erlang.byte_size(bin) - 2) |>
      :erlang.binary_to_integer()
  end

  defp read_bytes(socket, buffer) do
    {:ok, data, rest} = read_line(socket, buffer)
    <<?$, raw_num::binary>> = data
    num = to_int(raw_num)
    {:ok, num, rest}
  end

  defp read_args(_socket, 0, accum, buffer) do
    {:ok, :lists.reverse(accum), buffer}
  end

  defp read_args(socket, num, accum, buffer) do
    {:ok, num_bytes, buffer} = read_bytes(socket, buffer)
    # Read exact bytes for bulk string
    {:ok, data, buffer} = read_exact(socket, num_bytes, buffer)
    # Consume trailing CRLF
    {:ok, "\r\n", buffer} = read_exact(socket, 2, buffer)
    read_args(socket, num - 1, [data | accum], buffer)
  end

  defp read_exact(_socket, n, buffer) when byte_size(buffer) == n do
    {:ok, buffer, <<>>}
  end

  defp read_exact(_socket, n, buffer) when byte_size(buffer) > n do
    data = :binary.part(buffer, 0, n)
    rest = :binary.part(buffer, n, byte_size(buffer) - n)
    {:ok, data, rest}
  end

  defp read_exact(socket, n, buffer) do
    {:ok, chunk} = :gen_tcp.recv(socket, 0)
    read_exact(socket, n, buffer <> chunk)
  end

  defp parse_command(cmd, args) do
    case cmd do
      "CONFIG" -> {:config, args}
      "config" -> {:config, args}
      "SET" -> {:set, args}
      "set" -> {:set, args}
      "APPEND" -> {:append, args}
      "append" -> {:append, args}
      "GET" -> {:get, args}
      "get" -> {:get, args}
      "GETSET" -> {:getset, args}
      "getset" -> {:getset, args}
      "EXISTS" -> {:exists, args}
      "exists" -> {:exists, args}
      "DBSIZE" -> :dbsize
      "dbsize" -> :dbsize
      "FLUSHALL" -> :flushall
      "flushall" -> :flushall
      "PING" -> {:ping, args}
      "ping" -> {:ping, args}
      "INCR" -> {:incr, args}
      "incr" -> {:incr, args}
      "DECR" -> {:decr, args}
      "decr" -> {:decr, args}
      "DECRBY" -> {:decrby, args}
      "decrby" -> {:decrby, args}
      "INCRBY" -> {:incrby, args}
      "incrby" -> {:incrby, args}
      "SETEX" -> {:setex, args}
      "setex" -> {:setex, args}
      "TTL" -> {:ttl, args}
      "ttl" -> {:ttl, args}
      "RENAME" -> {:rename, args}
      "rename" -> {:rename, args}
      "RENAMENX" -> {:renamenx, args}
      "renamenx" -> {:renamenx, args}
      "RPUSH" -> {:rpush, args}
      "rpush" -> {:rpush, args}
      "RPUSHX" -> {:rpushx, args}
      "rpushx" -> {:rpushx, args}
      "LPUSH" -> {:lpush, args}
      "lpush" -> {:lpush, args}
      "LPUSHX" -> {:lpushx, args}
      "lpushx" -> {:lpushx, args}
      "LPOP" -> {:lpop, args}
      "lpop" -> {:lpop, args}
      "RPOP" -> {:rpop, args}
      "rpop" -> {:rpop, args}
      "LLEN" -> {:llen, args}
      "llen" -> {:llen, args}
      "LRANGE" -> {:lrange, args}
      "lrange" -> {:lrange, args}
      "LTRIM" -> {:ltrim, args}
      "ltrim" -> {:ltrim, args}
      "LSET" -> {:lset, args}
      "lset" -> {:lset, args}
      "LINDEX" -> {:lindex, args}
      "lindex" -> {:lindex, args}
      "RPOPLPUSH" -> {:rpoplpush, args}
      "rpoplpush" -> {:rpoplpush, args}
      "SADD" -> {:sadd, args}
      "sadd" -> {:sadd, args}
      "SREM" -> {:srem, args}
      "srem" -> {:srem, args}
      "SMEMBERS" -> {:smembers, args}
      "smembers" -> {:smembers, args}
      "SISMEMBER" -> {:sismember, args}
      "sismember" -> {:sismember, args}
      "SMISMEMBER" -> {:smismember, args}
      "smismember" -> {:smismember, args}
      "SCARD" -> {:scard, args}
      "scard" -> {:scard, args}
      "SUNION" -> {:sunion, args}
      "sunion" -> {:sunion, args}
      "SDIFF" -> {:sdiff, args}
      "sdiff" -> {:sdiff, args}
      "SINTER" -> {:sinter, args}
      "sinter" -> {:sinter, args}
      "SRANDMEMBER" -> {:srandmember, args}
      "srandmember" -> {:srandmember, args}
      "SPOP" -> {:spop, args}
      "spop" -> {:spop, args}
      "SMOVE" -> {:smove, args}
      "smove" -> {:smove, args}
      "SDIFFSTORE" -> {:sdiffstore, args}
      "sdiffstore" -> {:sdiffstore, args}
      "SUNIONSTORE" -> {:sunionstore, args}
      "sunionstore" -> {:sunionstore, args}
      "SINTERSTORE" -> {:sinterstore, args}
      "sinterstore" -> {:sinterstore, args}
      "HSET" -> {:hset, args}
      "hset" -> {:hset, args}
      "HMSET" -> {:hmset, args}
      "hmset" -> {:hmset, args}
      "HSETNX" -> {:hsetnx, args}
      "hsetnx" -> {:hsetnx, args}
      "HMGET" -> {:hmget, args}
      "hmget" -> {:hmget, args}
      "HLEN" -> {:hlen, args}
      "hlen" -> {:hlen, args}
      "HGET" -> {:hget, args}
      "hget" -> {:hget, args}
      "HGETALL" -> {:hgetall, args}
      "hgetall" -> {:hgetall, args}
      "HDEL" -> {:hdel, args}
      "hdel" -> {:hdel, args}
      "HKEYS" -> {:hkeys, args}
      "hkeys" -> {:hkeys, args}
      "HVALS" -> {:hvals, args}
      "hvals" -> {:hvals, args}
      "HEXISTS" -> {:hexists, args}
      "hexists" -> {:hexists, args}
      "HSTRLEN" -> {:hstrlen, args}
      "hstrlen" -> {:hstrlen, args}
      "HINCRBY" -> {:hincrby, args}
      "hincrby" -> {:hincrby, args}
      "DEL" -> {:del, args}
      "del" -> {:del, args}
    end
  end
end
