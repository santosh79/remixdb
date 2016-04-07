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
    import Remixdb.ResponseHandler, only: [send_nil: 1, send_response: 2]
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
      {:set, [key, val]} ->
        pid      = Remixdb.KeyHandler.get_or_create_pid :string, key
        response = Remixdb.String.set pid, val
        socket |> send_response(response)
      {:get, [key]} ->
        case Remixdb.KeyHandler.get_pid(:string, key) do
          nil ->
            socket |> send_nil
          pid ->
            val = Remixdb.String.get pid
            socket |> send_response(val)
        end
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

