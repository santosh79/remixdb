defmodule Remixdb do
  defmodule TcpServer do
    def start_server do
      port = 6379
      {:ok, socket} = :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])
      IO.puts "Accepting connections on port: #{port}"
      Remixdb.SimpleServer.start :remixdb_connection_handler, Remixdb.ClientHander
      Process.register self(), :remixdb_server
      loop_acceptor socket
    end
    
    def stop do
      Remixdb.ProcessCleaner.stop :remixdb_server
    end

    defp loop_acceptor(socket) do
      {:ok, client} = :gen_tcp.accept(socket)
      Remixdb.ClientHander.new_client client
      loop_acceptor socket
    end
  end

  defmodule Server do
    def start do
      spawn TcpServer, :start_server, []
      Remixdb.SimpleServer.start :remixdb_key_handler, Remixdb.KeyHandler
    end

    def stop do
      server_pid = Process.whereis :remixdb_server
      Process.exit server_pid, :kill
      Remixdb.TcpServer.stop
    end
  end
end

