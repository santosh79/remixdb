alias Remixdb.String, as: RSS
alias Remixdb.List, as: RL
alias Remixdb.Set, as: RST
alias Remixdb.Hash, as: RSH

defmodule Remixdb.RedisConnection do
  use GenServer

  def start_link(socket) do
    GenServer.start_link(__MODULE__, {:ok, socket}, [])
  end

  defmodule State do
    defstruct socket: nil, buffer: <<>>
  end

  def init({:ok, socket}) do
    {:ok, socket}
  end

  def handle_info(:read_socket, %State{socket: socket, buffer: buffer} = state) do
    case read_new_command(socket, buffer) do
      {:ok, [cmd | args], rest_buffer} ->
        parsed = parse_command(cmd, args)
        response = get_response(parsed)
        socket |> Remixdb.Redis.ResponseHandler.send_response(response)
        send(self(), :read_socket)
        {:noreply, %State{state | buffer: rest_buffer}}

      {:error, _reason} ->
        {:stop, :normal, state}
    end
  end

  def handle_info(_, state), do: {:noreply, state}

  def handle_cast(:start, socket) do
    send(self(), :read_socket)
    {:noreply, %State{socket: socket, buffer: <<>>}}
  end

  # Parsing functions moved from RedisParser
  defp read_new_command(socket, buffer) do
    {:ok, num_args, buffer} = read_number_args(socket, buffer)
    read_args(socket, num_args, [], buffer)
  end

  defp read_number_args(socket, buffer) do
    {:ok, data, rest} = read_line(socket, buffer)
    <<?*, raw_num::binary>> = data
    num = to_int(raw_num)
    {:ok, num, rest}
  end

  defp to_int(bin) when is_binary(bin) do
    bin
    |> :binary.part(0, :erlang.byte_size(bin) - 2)
    |> :erlang.binary_to_integer()
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
    {:ok, data, buffer} = read_exact(socket, num_bytes, buffer)
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
    missing = n - byte_size(buffer)
    {:ok, chunk} = :gen_tcp.recv(socket, missing) 
    read_exact(socket, n, buffer <> chunk)
  end

  defp read_line(socket, buffer) do
    case :binary.match(buffer, "\r\n") do
      {pos, 2} ->
        line = :binary.part(buffer, 0, pos + 2)
        rest = :binary.part(buffer, pos + 2, byte_size(buffer) - pos - 2)
        {:ok, line, rest}
      :nomatch ->
        {:ok, chunk} =  :gen_tcp.recv(socket, 0)
        read_line(socket, buffer <> chunk)
    end
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

  defp get_response(msg) do
    case msg do
      {:config, _} ->
        # SantoshTODO: Fix This Hard Code
        ["SAVE", "3600 1 300 100 60 10000"]

      {:ping, []} ->
        "PONG"

      {:ping, [res]} ->
        res

      :flushall ->
        datastructures()
        |> Enum.each(fn mod ->
          :erlang.apply(mod, :flushall, [])
        end)

      :dbsize ->
        datastructures()
        |> Enum.map(fn mod ->
          :erlang.apply(mod, :dbsize, [])
        end)
        |> Enum.sum()

      {:exists, [key]} ->
        case RSS.get(key) do
          nil -> 0
          _ -> 1
        end

      {:append, [key, val]} ->
        RSS.append(key, val)

      {:getset, [key, val]} ->
        RSS.getset(key, val)

      {:get, [key]} ->
        RSS.get(key)

      {:set, [key, val]} ->
        RSS.set(key, val)

      {:del, keys} ->
        RL.del(keys)

      {:incr, [key]} ->
        RSS.incr(key)

      {:incrby, [key, val]} ->
        RSS.incrby(key, val)

      {:decr, [key]} ->
        RSS.decr(key)

      {:decrby, [key, val]} ->
        RSS.decrby(key, val)

      {:setex, [_key, _timeout, _val]} ->
        raise "not implemented"

      {:ttl, [_key]} ->
        raise "not implemented"

      {:rename, [old_name, new_name]} ->
        res =
          datastructures()
          |> Enum.any?(fn mod -> :erlang.apply(mod, :rename, [old_name, new_name]) end)

        case res do
          false -> {:error, "ERR no such key"}
          _ -> "OK"
        end

      {:renamenx, [old_name, new_name]} ->
        case RSS.exists?(old_name) do
          true ->
            RSS.renamenx(old_name, new_name)

          false ->
            RL.renamenx(old_name, new_name)
        end

      {:rpushx, [name | items]} ->
        RL.rpushx(name, items)

      {:rpush, [name | items]} ->
        RL.rpush(name, items)

      {:lpushx, [name | items]} ->
        RL.rpushx(name, items)

      {:lpush, [name | items]} ->
        RL.lpush(name, items)

      {:lpop, [name]} ->
        RL.lpop(name)

      {:rpop, [name]} ->
        RL.rpop(name)

      {:llen, [list_name]} ->
        RL.llen(list_name)

      {:lrange, [name, st, en]} ->
        {start, ""} = Integer.parse(st)
        {stop, ""} = Integer.parse(en)
        RL.lrange(name, start, stop)

      {:ltrim, [name, st, en]} ->
        {start, ""} = Integer.parse(st)
        {stop, ""} = Integer.parse(en)
        RL.ltrim(name, start, stop)

      {:lset, [name, dd, val]} ->
        {idx, ""} = Integer.parse(dd)
        RL.lset(name, idx, val)

      {:lindex, [name, idx]} ->
        RL.lindex(name, idx)

      {:rpoplpush, [src, dest]} ->
        RL.rpoplpush(src, dest)

      {:sadd, [name | items]} ->
        RST.sadd(name, items)

      {:srem, [name | items]} ->
        RST.srem(name, items)

      {:smembers, [name]} ->
        RST.smembers(name)

      {:sismember, [name, keys]} ->
        RST.sismember(name, keys)

      {:smismember, name_and_keys} ->
        [name | keys] = name_and_keys
        RST.smismember(name, keys)

      {:scard, [name]} ->
        RST.scard(name)

      {:smove, [src, dest, member]} ->
        RST.smove(src, dest, member)

      {:srandmember, [set_name]} ->
        RST.srandmember(set_name)

      {:spop, [set_name]} ->
        RST.spop(set_name)

      {:sunion, keys} ->
        RST.sunion(keys)

      {:sdiff, keys} ->
        RST.sdiff(keys)

      {:sinter, keys} ->
        RST.sinter(keys)

      {:sdiffstore, args} ->
        RST.sdiffstore(args)

      {:sunionstore, args} ->
        RST.sunionstore(args)

      {:sinterstore, args} ->
        RST.sinterstore(args)

      {:hincrby, [hash_name, key, amt]} ->
        RSH.hincrby(hash_name, key, amt)

      {:hset, [key, field, val]} ->
        RSH.hset(key, field, val)

      {:hsetnx, [key, field, val]} ->
        RSH.hsetnx(key, field, val)

      {:hlen, [key]} ->
        RSH.hlen(key)

      {:hdel, [hash_name | keys]} ->
        RSH.hdel(hash_name, keys)

      {:hmget, [hash_name | fields]} ->
        RSH.hmget(hash_name, fields)

      {:hmset, [hash_name | fields]} ->
        RSH.hmset(hash_name, fields)

      {:hget, [hash_name, key_name]} ->
        RSH.hget(hash_name, key_name)

      {:hgetall, [key]} ->
        RSH.hgetall(key)

      {:hkeys, [key]} ->
        RSH.hkeys(key)

      {:hvals, [hash_name]} ->
        RSH.hvals(hash_name)

      {:hexists, [hash_name, key]} ->
        RSH.hexists(hash_name, key)

      {:hstrlen, [hash_name, key]} ->
        RSH.hstrlen(hash_name, key)
    end
  end

  defp datastructures() do
    [RSS, RL, RST, RSH]
  end
end

