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
    parser_pid = Remixdb.Parser.start socket, self()
    case get_parser_response(parser_pid) do
      {:set, args} ->
        IO.puts "got SET command: "
        IO.inspect args
        socket |> send_ok |> serve
      {:get, args} ->
        IO.puts "got GET command: "
        IO.inspect args
        socket |> send_bar |> serve
    end
  end

  defp get_parser_response(parser) do
    receive do
      {parser, args} -> args
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

  defp send_ok(socket) do
    IO.puts "sending ok"
    :gen_tcp.send socket, "+OK\r\n"
    socket
  end

  defp send_bar(socket) do
    IO.puts "sending bar"
    str = "$3\r\nBARr\r\n"
    :gen_tcp.send socket, "$3\r\nBAR\r\n"
    socket
  end

  defp write_line(line, socket) do
    :gen_tcp.send socket, line
  end
end

