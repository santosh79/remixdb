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
      serve(client)
      loop_acceptor(socket)
    end

    defp serve(socket) do
      socket
      |> read_line()
      |> write_line(socket)

      serve(socket)
    end

    defp read_line(socket) do
      {:ok, data} = :gen_tcp.recv(socket, 0)
      data
    end

    defp write_line(line, socket) do
      :gen_tcp.send(socket, line)
    end
  end

  defmodule Server do
    def start_tcp_server do
      TcpServer.start_server
    end
  end
end
