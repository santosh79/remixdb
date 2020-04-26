import Remixdb.KeyHandler, only: [flushall: 0, dbsize: 0, get_pid: 2, get_or_create_pid: 2, exists?: 1, rename_key: 2, renamenx_key: 2]
import Remixdb.ResponseHandler, only: [send_response: 2]

defmodule Remixdb.Client do
  use GenServer
  def start_link(socket) do
    GenServer.start_link __MODULE__, {:ok, socket}, []
  end

  defmodule State do
    defstruct socket: nil, parser: nil
  end

  def init({:ok, socket}) do
    send self(), :real_init
    {:ok, socket}
  end

  def handle_info(:real_init, socket) do
    {:ok, parser} = Remixdb.Parser.start_link(socket)
    send self(), :read_socket
    {:noreply, %State{socket: socket, parser: parser}}
  end

  def handle_info(:read_socket, %State{socket: socket, parser: parser} = state) do
    case Remixdb.Parser.read_command(parser) do
      {:error, _reason} -> :noop
      {:ok, msg} ->
        response = get_response(msg)
        socket |> send_response(response)
        send self(), :read_socket
        {:noreply, state}
    end
  end

  def handle_info(_, state), do: {:noreply, state}

  defp perform_set_single_arg_cmd(key, func) do
    func.(get_pid(:set, key))
  end

  defp get_response(msg) do
    case msg do
      {:ping, []} -> "PONG"
      {:ping, [res]} -> res
      :flushall -> flushall()
      :dbsize -> dbsize()
      {:exists, [key]} ->
        case exists?(key) do
          false -> 0
          true -> 1
        end
      {:append, [key, val]} ->
        get_or_create_pid(:string, key) |>
        Remixdb.String.append(val)
      {:getset, [key, val]} ->
        get_or_create_pid(:string, key) |>
        Remixdb.String.getset(val)
      {:set, [key, val]} ->
        get_or_create_pid(:string, key) |>
        Remixdb.String.set(val)
      {:incrby, [key, val]} ->
        get_or_create_pid(:string, key) |>
        Remixdb.String.incrby(val)
      {:decr, [key]} ->
        get_or_create_pid(:string, key) |>
        Remixdb.String.decr
      {:decrby, [key, val]} ->
        get_or_create_pid(:string, key) |>
        Remixdb.String.decrby(val)
      {:incr, [key]} ->
        get_or_create_pid(:string, key) |>
        Remixdb.String.incr
        {:get, [key]} ->
        get_pid(:string, key) |>
        Remixdb.String.get
        {:setex, [key, timeout, val]} ->
        get_or_create_pid(:string, key) |>
        Remixdb.String.setex(timeout, val)
        {:ttl, [key]} ->
        get_pid(:string, key) |> Remixdb.String.ttl
        {:rename, [old_name, new_name]} ->
        rename_key(old_name, new_name)
        {:renamenx, [old_name, new_name]} ->
        renamenx_key(old_name, new_name)
        {:rpushx, [key|items]} ->
        get_pid(:list, key) |>
        Remixdb.List.rpushx(items)
        {:rpush, [key|items]} ->
        get_or_create_pid(:list, key) |>
        Remixdb.List.rpush(items)
        {:lpushx, [key|items]} ->
        get_pid(:list, key) |>
        Remixdb.List.lpushx(items)
        {:lpush, [key|items]} ->
        get_or_create_pid(:list, key) |>
        Remixdb.List.lpush(items)
        {:lpop, [key]} ->
        get_pid(:list, key) |> Remixdb.List.lpop
        {:rpop, [key]} ->
        get_pid(:list, key) |> Remixdb.List.rpop
        {:llen, [key]} ->
        get_pid(:list, key) |> Remixdb.List.llen
        {:lrange, [key, start, stop]} ->
        get_pid(:list, key) |> Remixdb.List.lrange(start, stop)
        {:ltrim, [key, start, stop]} ->
        get_pid(:list, key) |> Remixdb.List.ltrim(start, stop)
        {:lset, [key, idx, val]} ->
        get_pid(:list, key) |> Remixdb.List.lset(idx, val)
        {:lindex, [key, idx]} ->
        get_pid(:list, key) |> Remixdb.List.lindex(idx)
        {:rpoplpush, [src, dest]} ->
        src_pid  = get_pid(:list, src)
        dest_pid = get_or_create_pid(:list, dest)
        Remixdb.List.rpoplpush src_pid, dest_pid
        {:sadd, [key|items]} ->
        get_or_create_pid(:set, key) |>
        Remixdb.Set.sadd(items)
        {:srem, [key|items]} ->
        get_or_create_pid(:set, key) |>
        Remixdb.Set.srem(items)
        {:smembers, [key]} ->
        perform_set_single_arg_cmd key, &Remixdb.Set.smembers/1
        {:sismember, [key, val]} ->
        get_pid(:set, key) |>
        Remixdb.Set.sismember(val)
        {:scard, [key]} ->
        perform_set_single_arg_cmd key, &Remixdb.Set.scard/1
        {:smove, [src, dest, member]} ->
        src_pid  = get_pid(:set, src)
        dest_pid = get_or_create_pid(:set, dest)
        Remixdb.Set.smove src_pid, dest_pid, member
        {:srandmember, [key]} ->
        perform_set_single_arg_cmd key, &Remixdb.Set.srandmember/1
        {:spop, [key]} ->
        perform_set_single_arg_cmd key, &Remixdb.Set.spop/1
        {:sunion, keys} ->
        perform_set_multi_args_cmd keys, &Remixdb.Set.sunion/1
        {:sdiff, keys} ->
        perform_set_multi_args_cmd keys, &Remixdb.Set.sdiff/1
        {:sinter, keys} ->
        perform_set_multi_args_cmd keys, &Remixdb.Set.sinter/1
        {:sdiffstore, args} ->
        perform_store_command &Remixdb.Set.sdiffstore/2, args
        {:sunionstore, args} ->
        perform_store_command &Remixdb.Set.sunionstore/2, args
        {:sinterstore, args} ->
        perform_store_command &Remixdb.Set.sinterstore/2, args
        {:hincrby, [key, field, val]} ->
        get_or_create_pid(:hash, key) |>
        Remixdb.Hash.hincrby(field, val)
        {:hset, [key, field, val]} ->
        get_or_create_pid(:hash, key) |>
        Remixdb.Hash.hset(%{field => val})
        {:hsetnx, [key, field, val]} ->
        get_or_create_pid(:hash, key) |>
        Remixdb.Hash.hsetnx(field, val)
        {:hlen, [key]} ->
        get_pid(:hash, key) |> Remixdb.Hash.hlen
        {:hdel, [key|fields]} ->
        get_pid(:hash, key) |> Remixdb.Hash.hdel(fields)
        {:hmget, [key|fields]} ->
        get_or_create_pid(:hash, key) |> Remixdb.Hash.hmget(fields)
        {:hmset, [key|fields]} ->
        get_or_create_pid(:hash, key) |> Remixdb.Hash.hmset(fields)
        {:hget, [key, field]} ->
        get_pid(:hash, key) |> Remixdb.Hash.hget(field)
        {:hgetall, [key]} ->
        get_pid(:hash, key) |> Remixdb.Hash.hgetall
        {:hkeys, [key]} ->
        get_pid(:hash, key) |> Remixdb.Hash.hkeys
        {:hvals, [key]} ->
        get_pid(:hash, key) |> Remixdb.Hash.hvals
        {:hexists, [key, field]} ->
        get_pid(:hash, key) |> Remixdb.Hash.hexists(field)
        {:hstrlen, [key, field]} ->
        get_pid(:hash, key) |> Remixdb.Hash.hstrlen(field)
    end
  end

  defp perform_set_multi_args_cmd(keys, func) do
    func.(keys |> Enum.map(&(get_pid(:set, &1))))
  end

  defp perform_store_command(func, [dest|keys]) do
    dest_pid = get_or_create_pid :set, dest
    key_pids =  keys |> Enum.map(&(get_pid(:set, &1)))
    func.(dest_pid, key_pids)
  end
end

