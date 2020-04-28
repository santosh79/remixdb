defmodule Remixdb.Server do
  use GenServer

  @name :remixdb_server

  defmodule State do
    defstruct tcp_server_pid: nil, key_handler_pid: nil
  end

  def start_link do
    GenServer.start_link __MODULE__, :ok, name: @name
  end

  def init(:ok) do
    send self(), :long_init
    {:ok, nil}
  end

  def handle_info(:long_init, _state) do
    IO.puts "\n\n --- started remixdb.server at -- "
    IO.inspect self()
    IO.puts "\n\n"

    tcp_pid = start_tcp_server()
    key_handler_pid = start_key_handler()

    {:noreply, %State{tcp_server_pid: tcp_pid, key_handler_pid: key_handler_pid}}
  end

  defp start_key_handler() do
    kp = Remixdb.KeyHandler.start_link
    IO.puts "\n\n --- started Remixdb.KeyHandler at -- "
    IO.inspect kp
    IO.puts "\n\n"
    kp
  end

  defp start_tcp_server() do
    tcp_pid = spawn_link(Remixdb.TcpServer, :start, [])
    IO.puts "\n\n --- started Remixdb.TcpServer at -- "
    IO.inspect tcp_pid
    IO.puts "\n\n"

    Process.register tcp_pid, :remixdb_tcp_server
    tcp_pid
  end

end

