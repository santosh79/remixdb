defmodule Remixdb do
  defmodule TcpServer do
    def start_server do
      port = 6379
      {:ok, socket} = :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])
      IO.puts "Accepting connections on port: #{port}"
      Process.register self(), :remixdb_server
      loop_acceptor socket
    end
    
    def stop do
      Remixdb.ProcessCleaner.stop :remixdb_server
    end

    defp loop_acceptor(socket) do
      {:ok, client} = :gen_tcp.accept(socket)
      Remixdb.Client.start client
      loop_acceptor socket
    end
  end

  defmodule Server do
    def start do
      spawn_link TcpServer, :start_server, []
      Remixdb.KeyHandler.start_link
    end

    def stop do
      server_pid = Process.whereis :remixdb_server
      Process.exit server_pid, :kill
      Remixdb.TcpServer.stop
    end
  end
end

