defmodule Remixdb.Parsers.RedisParser do
  use GenServer

  def start_link(socket) do
    GenServer.start_link(__MODULE__, {:ok, socket}, [])
  end

  def init({:ok, socket}) do
    {:ok, socket}
  end

  def read_command(pid) do
    GenServer.call(pid, :read_command, :infinity)
  end

  def handle_call(:read_command, _from, socket = state) do
    {:ok, [cmd | args]} = read_new_command(socket)
    res = parse_command(cmd, args)
    response = {:ok, res}
    {:reply, response, state}
  end

  def handle_info(_, state), do: {:noreply, state}

  defp read_new_command(socket) do
    {:ok, num_args} = read_number_args(socket)
    read_args(socket, num_args)
  end

  defp read_args(socket, num) do
    read_args(socket, num, [])
  end

  defp read_args(_socket, 0, accum) do
    {:ok, :lists.reverse(accum)}
  end

  defp read_args(socket, num, accum) do
    {:ok, num_bytes} = read_bytes(socket)
    {:ok, data} = read_line(socket)

    # Ensure the number of bytes matches
    # Subtract 2 for the trailing /r/n
    ^num_bytes = :erlang.byte_size(data) - 2

    msg = data |> :binary.part(0, :erlang.byte_size(data) - 2)

    read_args(socket, num - 1, [msg | accum])
  end

  defp read_bytes(socket) do
    {:ok, data} = read_line(socket)
    {:ok, line_to_int(data)}
  end

  defp read_line(socket) do
    :gen_tcp.recv(socket, 0)
  end

  @doc """
  This reads a line of format "*3\r\n". And returns 3. Here 3 is any number.
  """
  def read_number_args(socket) do
    {:ok, data} = read_line(socket)
    num_args = data |> line_to_int
    {:ok, num_args}
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
    end
  end
end
