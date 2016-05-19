defmodule Remixdb.Client do
  def start(socket) do
    spawn Remixdb.Client, :loop, [socket]
  end

  def loop(socket) do
    stream = %Remixdb.Socket{socket: socket}
    spawn_link Remixdb.Parser, :start, [stream, self]
    socket |>
    # print_new_connection |>
    serve
  end

  def serve(socket) do
    import Remixdb.ResponseHandler, only: [send_response: 2]
    response = get_response
    socket |> send_response(response) |> serve
  end

  defp print_new_connection(socket) do
    IO.puts "new connection from"
    print_sock_info
    socket
  end

  defp print_sock_info() do
    remote_host = Process.get :remote_host
    remote_port = Process.get :remote_port
    IO.puts "remote host: "
    IO.inspect remote_host
    IO.puts "and remote port: #{remote_port}"
  end

  defp get_response() do
    import Remixdb.KeyHandler, only: [flushall: 0, dbsize: 0, get_pid: 2, get_or_create_pid: 2, exists?: 1, rename_key: 2, renamenx_key: 2]
    receive do
      {:ping, []} -> "PONG"
      {:ping, [res]} -> res
      :flushall -> flushall
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
      {:sadd, [key, val]} ->
        get_or_create_pid(:set, key) |>
        Remixdb.Set.sadd(val)
      {:smembers, [key]} ->
        get_pid(:set, key) |>
        Remixdb.Set.smembers
      {:sismember, [key, val]} ->
        get_pid(:set, key) |>
        Remixdb.Set.sismember(val)
      {:scard, [key]} ->
        get_pid(:set, key) |>
        Remixdb.Set.scard
    end
  end
end

