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
    receive do
      {:ping, []} ->
        socket |> send_response("PONG")
      {:ping, [res]} ->
        socket |> send_response(res)
      :flushall ->
        response = Remixdb.KeyHandler.flushall
        socket |> send_response(response)
      :dbsize ->
        val = Remixdb.KeyHandler.dbsize()
        socket |> send_response(val)
      {:exists, [key]} ->
        case Remixdb.KeyHandler.exists?(key) do
          false ->
            socket |> send_response(0)
          true ->
            socket |> send_response(1)
        end
      {:append, [key, val]} ->
        pid = Remixdb.KeyHandler.get_or_create_pid :string, key
        response = Remixdb.String.append pid, val
        socket |> send_response(response)
      {:getset, [key, val]} ->
        pid      = Remixdb.KeyHandler.get_or_create_pid :string, key
        response = Remixdb.String.getset pid, val
        socket |> send_response(response)
      {:set, [key, val]} ->
        pid      = Remixdb.KeyHandler.get_or_create_pid :string, key
        response = Remixdb.String.set pid, val
        socket |> send_response(response)
      {:incrby, [key, val]} ->
        pid = Remixdb.KeyHandler.get_or_create_pid :string, key
        response = Remixdb.String.incrby pid, val
        socket |> send_response(response)
      {:decr, [key]} ->
        pid = Remixdb.KeyHandler.get_or_create_pid :string, key
        response = Remixdb.String.decr pid
        socket |> send_response(response)
      {:decrby, [key, val]} ->
        pid = Remixdb.KeyHandler.get_or_create_pid :string, key
        response = Remixdb.String.decrby pid, val
        socket |> send_response(response)
      {:incr, [key]} ->
        pid = Remixdb.KeyHandler.get_or_create_pid :string, key
        response = Remixdb.String.incr pid
        socket |> send_response(response)
      {:get, [key]} ->
        val = case Remixdb.KeyHandler.get_pid(:string, key) do
          nil -> nil
          pid -> val = Remixdb.String.get(pid)
        end
        socket |> send_response(val)
      {:setex, [key, timeout, val]} ->
        pid = Remixdb.KeyHandler.get_or_create_pid :string, key
        response = Remixdb.String.setex pid, timeout, val
        socket |> send_response(response)
      {:ttl, [key]} ->
        pid      = Remixdb.KeyHandler.get_pid :string, key
        response = Remixdb.String.ttl pid
        socket |> send_response(response)
    end
    socket |> serve
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
end

