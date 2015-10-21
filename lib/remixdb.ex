defmodule Remixdb do
  defmodule TcpServer do
    def start_server do
      port = 6379
      {:ok, socket} = :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])
      IO.puts "Accepting connections on port: #{port}"
      pid = Remixdb.ClientHander.start
      Process.register pid, :remixdb_connection_handler
      loop_acceptor socket
    end
    

    defp loop_acceptor(socket) do
      {:ok, client} = :gen_tcp.accept(socket)
      connection_handler = Process.whereis :remixdb_connection_handler
      send connection_handler, {:new_client, client}
      loop_acceptor socket
    end
  end

  defmodule Server do
    def start_tcp_server do
      server_pid = spawn TcpServer, :start_server, []
    end
  end
end
