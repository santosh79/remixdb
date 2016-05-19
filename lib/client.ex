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
    receive do
      {:ping, []} -> "PONG"
      {:ping, [res]} -> res
      :flushall -> Remixdb.KeyHandler.flushall
      :dbsize -> Remixdb.KeyHandler.dbsize()
      {:exists, [key]} ->
        case Remixdb.KeyHandler.exists?(key) do
          false -> 0
          true -> 1
        end
      {:append, [key, val]} ->
        Remixdb.KeyHandler.get_or_create_pid(:string, key) |>
        Remixdb.String.append(val)
      {:getset, [key, val]} ->
        Remixdb.KeyHandler.get_or_create_pid(:string, key) |>
        Remixdb.String.getset(val)
      {:set, [key, val]} ->
         Remixdb.KeyHandler.get_or_create_pid(:string, key) |>
        Remixdb.String.set(val)
      {:incrby, [key, val]} ->
        Remixdb.KeyHandler.get_or_create_pid(:string, key) |>
        Remixdb.String.incrby(val)
      {:decr, [key]} ->
        Remixdb.KeyHandler.get_or_create_pid(:string, key) |>
        Remixdb.String.decr
      {:decrby, [key, val]} ->
        Remixdb.KeyHandler.get_or_create_pid(:string, key) |>
        Remixdb.String.decrby(val)
      {:incr, [key]} ->
        Remixdb.KeyHandler.get_or_create_pid(:string, key) |>
        Remixdb.String.incr
      {:get, [key]} ->
        Remixdb.KeyHandler.get_pid(:string, key) |>
        Remixdb.String.get
      {:setex, [key, timeout, val]} ->
        Remixdb.KeyHandler.get_or_create_pid(:string, key) |>
        Remixdb.String.setex(timeout, val)
      {:ttl, [key]} ->
        Remixdb.KeyHandler.get_pid(:string, key) |> Remixdb.String.ttl
      {:rename, [old_name, new_name]} ->
        Remixdb.KeyHandler.rename_key(old_name, new_name)
      {:renamenx, [old_name, new_name]} ->
        Remixdb.KeyHandler.renamenx_key(old_name, new_name)
      {:rpushx, [key|items]} ->
        Remixdb.KeyHandler.get_pid(:list, key) |>
        Remixdb.List.rpushx(items)
      {:rpush, [key|items]} ->
        Remixdb.KeyHandler.get_or_create_pid(:list, key) |>
        Remixdb.List.rpush(items)
      {:lpushx, [key|items]} ->
        Remixdb.KeyHandler.get_pid(:list, key) |>
        Remixdb.List.lpushx(items)
      {:lpush, [key|items]} ->
        Remixdb.KeyHandler.get_or_create_pid(:list, key) |>
        Remixdb.List.lpush(items)
      {:lpop, [key]} ->
        Remixdb.KeyHandler.get_pid(:list, key) |> Remixdb.List.lpop
      {:rpop, [key]} ->
        Remixdb.KeyHandler.get_pid(:list, key) |> Remixdb.List.rpop
      {:llen, [key]} ->
        Remixdb.KeyHandler.get_pid(:list, key) |> Remixdb.List.llen
      {:lrange, [key, start, stop]} ->
        Remixdb.KeyHandler.get_pid(:list, key) |> Remixdb.List.lrange(start, stop)
      {:ltrim, [key, start, stop]} ->
        Remixdb.KeyHandler.get_pid(:list, key) |> Remixdb.List.ltrim(start, stop)
      {:lset, [key, idx, val]} ->
        Remixdb.KeyHandler.get_pid(:list, key) |> Remixdb.List.lset(idx, val)
      {:lindex, [key, idx]} ->
        Remixdb.KeyHandler.get_pid(:list, key) |> Remixdb.List.lindex(idx)
      {:rpoplpush, [src, dest]} ->
        src_pid  = Remixdb.KeyHandler.get_pid(:list, src)
        dest_pid = Remixdb.KeyHandler.get_or_create_pid(:list, dest)
        Remixdb.List.rpoplpush src_pid, dest_pid
      {:sadd, [key, val]} ->
        Remixdb.KeyHandler.get_or_create_pid(:set, key) |>
        Remixdb.Set.sadd(val)
      {:smembers, [key]} ->
        Remixdb.KeyHandler.get_pid(:set, key) |>
        Remixdb.Set.smembers
      {:sismember, [key, val]} ->
        Remixdb.KeyHandler.get_pid(:set, key) |>
        Remixdb.Set.sismember(val)
      {:scard, [key]} ->
        Remixdb.KeyHandler.get_pid(:set, key) |>
        Remixdb.Set.scard
    end
  end
end

