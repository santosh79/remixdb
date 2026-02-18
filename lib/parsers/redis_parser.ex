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
    case read_line(socket, buffer) do
      {:ok, data, rest} -> {:ok, line_to_int(data), rest}
      {:error, reason} -> {:error, reason}
    end
  end

  defp read_bytes(socket, buffer) do
    case read_line(socket, buffer) do
      {:ok, data, rest} -> {:ok, line_to_int(data), rest}
      {:error, reason} -> {:error, reason}
    end
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

  defp read_exact(_socket, n, buffer) when byte_size(buffer) >= n do
    data = :binary.part(buffer, 0, n)
    rest = :binary.part(buffer, n, byte_size(buffer) - n)
    {:ok, data, rest}
  end

  defp read_exact(socket, n, buffer) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, chunk} -> read_exact(socket, n, buffer <> chunk)
      {:error, reason} -> {:error, reason}
    end
  end

  defp line_to_int(data) do
    data |> :binary.part(1, :erlang.byte_size(data) - 3) |> :erlang.binary_to_integer()
  end

  defp parse_command(cmd, args) do
    case cmd |> String.upcase() do
      "CONFIG" -> {:config, args}
      "SET" -> {:set, args}
      "APPEND" -> {:append, args}
      "GET" -> {:get, args}
      "GETSET" -> {:getset, args}
      "EXISTS" -> {:exists, args}
      "DBSIZE" -> :dbsize
      "FLUSHALL" -> :flushall
      "PING" -> {:ping, args}
      "INCR" -> {:incr, args}
      "DECR" -> {:decr, args}
      "DECRBY" -> {:decrby, args}
      "INCRBY" -> {:incrby, args}
      "SETEX" -> {:setex, args}
      "TTL" -> {:ttl, args}
      "RENAME" -> {:rename, args}
      "RENAMENX" -> {:renamenx, args}
      "RPUSH" -> {:rpush, args}
      "RPUSHX" -> {:rpushx, args}
      "LPUSH" -> {:lpush, args}
      "LPUSHX" -> {:lpushx, args}
      "LPOP" -> {:lpop, args}
      "RPOP" -> {:rpop, args}
      "LLEN" -> {:llen, args}
      "LRANGE" -> {:lrange, args}
      "LTRIM" -> {:ltrim, args}
      "LSET" -> {:lset, args}
      "LINDEX" -> {:lindex, args}
      "RPOPLPUSH" -> {:rpoplpush, args}
      "SADD" -> {:sadd, args}
      "SREM" -> {:srem, args}
      "SMEMBERS" -> {:smembers, args}
      "SISMEMBER" -> {:sismember, args}
      "SMISMEMBER" -> {:smismember, args}
      "SCARD" -> {:scard, args}
      "SUNION" -> {:sunion, args}
      "SDIFF" -> {:sdiff, args}
      "SINTER" -> {:sinter, args}
      "SRANDMEMBER" -> {:srandmember, args}
      "SPOP" -> {:spop, args}
      "SMOVE" -> {:smove, args}
      "SDIFFSTORE" -> {:sdiffstore, args}
      "SUNIONSTORE" -> {:sunionstore, args}
      "SINTERSTORE" -> {:sinterstore, args}
      "HSET" -> {:hset, args}
      "HMSET" -> {:hmset, args}
      "HSETNX" -> {:hsetnx, args}
      "HMGET" -> {:hmget, args}
      "HLEN" -> {:hlen, args}
      "HGET" -> {:hget, args}
      "HGETALL" -> {:hgetall, args}
      "HDEL" -> {:hdel, args}
      "HKEYS" -> {:hkeys, args}
      "HVALS" -> {:hvals, args}
      "HEXISTS" -> {:hexists, args}
      "HSTRLEN" -> {:hstrlen, args}
      "HINCRBY" -> {:hincrby, args}
      "DEL" -> {:del, args}
    end
  end
end
