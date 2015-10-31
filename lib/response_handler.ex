defmodule Remixdb.ResponseHandler do
  def send_nil(socket) do
    :gen_tcp.send socket, "$-1\r\n"
    socket
  end

  def send_response(socket, val) when is_bitstring(val) do
    val_bytes = val |> String.length |> Integer.to_string
    msg = "$" <> val_bytes <> "\r\n" <> val <> "\r\n"
    :gen_tcp.send socket, msg
    socket
  end
  def send_response(socket, num) when is_integer(num) do
    response = ":" <> (num |> Integer.to_string) <> "\r\n"
    :gen_tcp.send socket, response
  end
  def send_response(socket, :ok) do
    socket |> send_ok
  end
  def send_ok(socket) do
    :gen_tcp.send socket, "+OK\r\n"
    socket
  end
end

