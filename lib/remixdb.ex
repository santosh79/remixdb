defmodule Remixdb do
  defmodule TcpServer do
    def start_server do
      port = 6379
      {:ok, socket} = :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])
      IO.puts "Accepting connections on port: #{port}"
      loop_acceptor socket
    end
    

    defp loop_acceptor(socket) do
      {:ok, client} = :gen_tcp.accept(socket)
      IO.puts "got new connection"
      serve(client)
      loop_acceptor(socket)
    end

    defp serve(socket) do
      serve socket, 0
    end

    defp serve(socket, num) do
      IO.puts "num: #{num}"

      socket
      |> read_line()

      case num do
        6 -> send_ok(socket)
        11 -> send_bar(socket)
        _  -> :void
      end
      serve socket, (num + 1)
    end

    defp read_line(socket) do
      val = :gen_tcp.recv(socket, 0)
      case val do
        {:ok, data} ->
          IO.puts "data: #{data}"
          data
        {:error, _} ->
          IO.puts "client closed the connection"
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

  defmodule Server do
    def start_tcp_server do
      server_pid = spawn TcpServer, :start_server, []
    end
  end
end
