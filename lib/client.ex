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
        pid = Remixdb.KeyHandler.get_or_create_pid :string, key
        Remixdb.String.append pid, val
      {:getset, [key, val]} ->
        pid = Remixdb.KeyHandler.get_or_create_pid :string, key
        Remixdb.String.getset pid, val
      {:set, [key, val]} ->
        pid = Remixdb.KeyHandler.get_or_create_pid :string, key
        Remixdb.String.set pid, val
      {:incrby, [key, val]} ->
        pid = Remixdb.KeyHandler.get_or_create_pid :string, key
        Remixdb.String.incrby pid, val
      {:decr, [key]} ->
        pid = Remixdb.KeyHandler.get_or_create_pid :string, key
        Remixdb.String.decr pid
      {:decrby, [key, val]} ->
        pid = Remixdb.KeyHandler.get_or_create_pid :string, key
        Remixdb.String.decrby pid, val
      {:incr, [key]} ->
        pid = Remixdb.KeyHandler.get_or_create_pid :string, key
        Remixdb.String.incr pid
      {:get, [key]} ->
        result = case Remixdb.KeyHandler.get_pid(:string, key) do
          nil -> nil
          pid -> Remixdb.String.get(pid)
        end
        result
      {:setex, [key, timeout, val]} ->
        pid = Remixdb.KeyHandler.get_or_create_pid :string, key
        spawn(fn ->
          :timer.sleep(String.to_integer(timeout) * 1_000)
          Remixdb.String.expire pid
          Remixdb.KeyHandler.remove key
        end)
        Remixdb.String.setex pid, timeout, val
      {:ttl, [key]} ->
        case Remixdb.KeyHandler.get_pid(:string, key) do
          nil -> -2
          pid -> Remixdb.String.ttl(pid)
        end
    end
  end
end

