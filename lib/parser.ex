defmodule Remixdb.Parser do
  use GenServer
  def start_link(stream, client) do
    GenServer.start_link __MODULE__, {:ok, stream, client}, []
  end

  def init({:ok, stream, client}) do
    send self(), :loop
    {:ok, [stream, client]}
  end

  def handle_info(:loop, [stream, client] = state) do
    case read_new_command(stream) do
      {:error, reason} ->
        IO.puts "parser bad request #{inspect reason}"
      {:ok, [cmd|args]} ->
        response = case (cmd |> String.upcase) do
          "SET"         -> {:set, args}
          "APPEND"      -> {:append, args}
          "GET"         -> {:get, args}
          "GETSET"      -> {:getset, args}
          "EXISTS"      -> {:exists, args}
          "DBSIZE"      -> :dbsize
          "FLUSHALL"    -> :flushall
          "PING"        -> {:ping, args}
          "INCR"        -> {:incr, args}
          "DECR"        -> {:decr, args}
          "DECRBY"      -> {:decrby, args}
          "INCRBY"      -> {:incrby, args}
          "SETEX"       -> {:setex, args}
          "TTL"         -> {:ttl, args}
          "RENAME"      -> {:rename, args}
          "RENAMENX"    -> {:renamenx, args}
          "RPUSH"       -> {:rpush, args}
          "RPUSHX"      -> {:rpushx, args}
          "LPUSH"       -> {:lpush, args}
          "LPUSHX"      -> {:lpushx, args}
          "LPOP"        -> {:lpop, args}
          "RPOP"        -> {:rpop, args}
          "LLEN"        -> {:llen, args}
          "LRANGE"      -> {:lrange, args}
          "LTRIM"       -> {:ltrim, args}
          "LSET"        -> {:lset, args}
          "LINDEX"      -> {:lindex, args}
          "RPOPLPUSH"   -> {:rpoplpush, args}
          "SADD"        -> {:sadd, args}
          "SREM"        -> {:srem, args}
          "SMEMBERS"    -> {:smembers, args}
          "SISMEMBER"   -> {:sismember, args}
          "SCARD"       -> {:scard, args}
          "SUNION"      -> {:sunion, args}
          "SDIFF"       -> {:sdiff, args}
          "SINTER"      -> {:sinter, args}
          "SRANDMEMBER" -> {:srandmember, args}
          "SPOP"        -> {:spop, args}
          "SMOVE"       -> {:smove, args}
          "SDIFFSTORE"  -> {:sdiffstore, args}
          "SUNIONSTORE" -> {:sunionstore, args}
          "SINTERSTORE" -> {:sinterstore, args}
          "HSET"        -> {:hset, args}
          "HMSET"       -> {:hmset, args}
          "HSETNX"      -> {:hsetnx, args}
          "HMGET"       -> {:hmget, args}
          "HLEN"        -> {:hlen, args}
          "HGET"        -> {:hget, args}
          "HGETALL"     -> {:hgetall, args}
          "HDEL"        -> {:hdel, args}
          "HKEYS"       -> {:hkeys, args}
          "HVALS"       -> {:hvals, args}
          "HEXISTS"     -> {:hexists, args}
          "HSTRLEN"     -> {:hstrlen, args}
          "HINCRBY"     -> {:hincrby, args}
          cmd ->
            IO.puts "Parser: unknown command: #{inspect cmd}"
            nil
        end
        GenServer.cast client, response
        send self(), :loop
        {:noreply, state}
    end
  end
  def handle_info(_, state), do: {:noreply, state}

  defp read_new_command(stream) do
    case read_number_args(stream) do
      {:error, reason} -> {:error, reason}
      {:ok, num_args} ->
        read_args stream, num_args
    end
  end

  defp read_args(stream, num) do
    read_args stream, num, []
  end
  defp read_args(_stream, 0, accum) do
    {:ok, accum}
  end

  defp read_args(stream, num, accum) do
    case read_bytes(stream) do
      {:ok, num_bytes} ->
        case read_data(stream, num_bytes) do
          {:ok, data} ->
            msg = data |> String.replace(~r/(.+)\r\n$/, "\\1")
            read_args stream, (num - 1), (accum ++ [msg])
        end
    end
  end

  defp read_data(stream, num_bytes) do
    val = Remixdb.StreamReader.read_line stream
    case val do
      {:ok, data} ->
        msg = data |> String.replace(~r/(.+)\r\n/, "\\1")
        case String.length(msg) do
          ^num_bytes ->
            {:ok, msg}
          _ -> {:error, msg}
        end
    end
  end

  defp read_bytes(stream) do
    val = Remixdb.StreamReader.read_line stream
    case val do
      {:ok, data} ->
        {num_bytes, ""} = data |> String.replace(~r/\$(\d+)\r\n/, "\\1") |> Integer.parse
        {:ok, num_bytes}
    end
  end

  @doc """
  This reads a line of format "*3\r\n". And returns 3. Here 3 is any number.
  """
  def read_number_args(stream) do
    val = Remixdb.StreamReader.read_line stream
    case val do
      {:ok, data} ->
        {num_args, ""} = data |>
          String.replace(~r/\*(\d+)\r\n/,"\\1") |> Integer.parse
        {:ok, num_args}
      {:error, reason} ->
        IO.puts "error with connection: #{reason}"
        {:error, reason}
    end
  end
end

