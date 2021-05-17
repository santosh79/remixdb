defmodule Remixdb.TcpServer do
  use GenServer

  @name :remixdb_tcp_server

  def start_link(_args) do
    GenServer.start_link __MODULE__, %{port: 6379, client_mod: Remixdb.RedisConnection}, name: @name
  end

  def init(args) do
    send self(), :long_init
    {:ok, args}
  end

  def handle_info(:long_init, %{port: port} = state) do
    {:ok, socket} = :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true, backlog: 1_000])
    :io.format("~p at port: ~p ~n", [__MODULE__, port])

    updated_state = state |> Map.put(:socket, socket)
    Process.flag :trap_exit, true

    send self(), :accept
    {:noreply, updated_state}
  end

  def handle_info({:EXIT, from, _reason}, state) do
    :io.format("tcp_server -- connection: ~p died~n", [from])
    {:noreply, state}
  end

  def handle_info(:accept, %{socket: socket, client_mod: client_mod} = state) do
    case :gen_tcp.accept(socket, 1_000) do
      {:error, :timeout} -> nil
      {:ok, client_sock} ->
        :erlang.apply client_mod, :start_link, [client_sock]
    end
    send self(), :accept
    {:noreply, state}
  end
end
