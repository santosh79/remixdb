import Remixdb.Redis.ResponseHandler, only: [send_ok: 1]

defmodule Remixdb.RedisEchoClient do
  use GenServer
  def start_link(socket) do
    GenServer.start_link __MODULE__, {:ok, socket}, []
  end

  defmodule State do
    defstruct socket: nil, parser: nil
  end

  def init({:ok, socket}) do
    send self(), :real_init
    {:ok, socket}
  end

  def handle_info(:real_init, socket) do
    {:ok, parser} = Remixdb.Parsers.RedisParser.start_link(socket)
    send self(), :read_socket
    {:noreply, %State{socket: socket, parser: parser}}
  end

  def handle_info(:read_socket, %State{socket: socket, parser: parser} = state) do
    {:ok, _msg} = Remixdb.Parser.read_command(parser)
    socket |>  send_ok
    send self(), :read_socket
    {:noreply, state}
  end
end

