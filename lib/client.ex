defmodule Remixdb.Client do
  def start(socket) do
    spawn Remixdb.Client, :loop, [socket]
  end

  def loop(socket) do
    socket |>
    store_sock_info |>
    print_new_connection |>
    serve(Remixdb.Parser.start %Remixdb.Socket{socket: socket}, self())
  end


  defp print_new_connection(socket) do
    IO.puts "new connection from"
    print_sock_info
    socket
  end

  defp print_connection_closed() do
    IO.puts "client closed connection"
    print_sock_info
  end

  defp wait_for_ok(key_pid) do
    receive do
      {:ok, ^key_pid} -> :void
    end
  end

  defp serve(socket, parser) do
    import Remixdb.ResponseHandler, only: [send_ok: 1, send_nil: 1, send_val: 2, send_integer_response: 2]
    case get_parser_response(parser) do
      {:exists, [key]} ->
        case Remixdb.KeyHandler.exists?(key) do
          false ->
            socket |> send_integer_response(0)
          true ->
            socket |> send_integer_response(1)
        end
      {:set, [key, val]} ->
        Remixdb.KeyHandler.set key, val
        socket |> send_ok
      {:get, [key]} ->
        case Remixdb.KeyHandler.get(key) do
          nil ->
            socket |> send_nil
          val ->
            socket |> send_val(val)
        end
    end
    socket |> serve(parser)
  end

  defp get_parser_response(parser) do
    receive do
      {^parser, args} -> args
    end
  end

  defp store_sock_info(socket) do
    peer_info = :inet.peername socket
    case peer_info do
      {:ok, {host_ip, port}} ->
        IO.inspect host_ip
        Process.put :remote_host, host_ip
        Process.put :remote_port, port
      {_} -> :void
    end
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

