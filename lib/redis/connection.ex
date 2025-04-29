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
    defstruct socket: nil, parser: nil
  end

  def init({:ok, socket}) do
    send(self(), :real_init)
    {:ok, socket}
  end

  def handle_info(:real_init, socket) do
    {:ok, parser} = Remixdb.Parsers.RedisParser.start_link(socket)
    send(self(), :read_socket)
    {:noreply, %State{socket: socket, parser: parser}}
  end

  def handle_info(:read_socket, %State{socket: socket, parser: parser} = state) do
    {:ok, msg} = Remixdb.Parser.read_command(parser)
    re = get_response(msg)
    socket |> Remixdb.Redis.ResponseHandler.send_response(re)
    send(self(), :read_socket)
    {:noreply, state}
  end

  def handle_info(_, state), do: {:noreply, state}

  defp get_response(msg) do
    case msg do
      {:config, _} ->
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
          |> Enum.any?(fn mod ->
            :erlang.apply(mod, :rename, [old_name, new_name])
          end)

        case res do
          false -> {:error, "ERR no such key"}
          _ -> "OK"
        end

      {:renamenx, [_old_name, _new_name]} ->
        raise "not implemented!"

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
        # TODO: Clean this up
        RL.lrange(name, start, stop)

      {:ltrim, [name, st, en]} ->
        {start, ""} = Integer.parse(st)
        {stop, ""} = Integer.parse(en)
        # TODO: Clean this up
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
