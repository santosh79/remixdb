defmodule Remixdb.Socket do
  defstruct socket: nil
end

defprotocol Remixdb.StreamReader do
  def read_line(stream)
end

defimpl Remixdb.StreamReader, for: Remixdb.Socket do
  def read_line(sock) do
    :gen_tcp.recv sock.socket, 0
  end
end
