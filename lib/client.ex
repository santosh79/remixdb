defmodule Remixdb.Client do
  def start(socket) do
    spawn Remixdb.Client, :loop, [socket]
  end

  def loop(socket) do
    socket |>
    store_sock_info |>
    print_new_connection |>
    serve
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

  defp serve(socket) do
    serve socket, 0
  end

  defp serve(socket, num) do
    IO.puts "num: #{num}"
    val = socket |> read_line()

    case val do
      :ok ->
        case num do
          6 -> send_ok(socket)
          11 -> send_bar(socket)
          _  -> :void
        end
        serve socket, (num + 1)
      :error ->
        print_connection_closed
        :inet.close socket
        exit :client_closed
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

  defp read_line(socket) do
    val = :gen_tcp.recv(socket, 0)
    case val do
      {:ok, data} ->
        IO.puts "data: #{data}"
        :ok
      {:error, _reason} ->
        IO.puts "error with connection: #{_reason}"
        :error
    end
  end

  defp send_ok(socket) do
    IO.puts "sending ok"
    :gen_tcp.send socket, "+OK\r\n"
  end

  defp send_bar(socket) do
    IO.puts "sending bar"
    str = "$3\r\nBARr\r\n"
    :gen_tcp.send socket, "$3\r\nBAR\r\n"
  end

  defp write_line(line, socket) do
    :gen_tcp.send socket, line
  end
end

