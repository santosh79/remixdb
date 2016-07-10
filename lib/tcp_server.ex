defmodule Remixdb.TcpServer do
  use GenServer

  def start_link do
    GenServer.start_link __MODULE__, :ok, []
  end

  def init(:ok) do
    send self, :real_init
    {:ok, nil}
  end

  def handle_info(:real_init, _state) do
    port = 6379
    {:ok, socket} = :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])
    IO.puts "Accepting connections on port: #{port}"
    Process.register self(), :remixdb_tcp_server
    GenServer.cast self, :listen
    {:noreply, socket}
  end

  def handle_cast(:listen, socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    Remixdb.Client.start_link client
    GenServer.cast self, :listen
    {:noreply, socket}
  end

  def terminate(:normal, socket) do
    socket |> :gen_tcp.close
    :ok
  end
end
