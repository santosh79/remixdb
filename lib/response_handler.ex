defmodule Remixdb.ResponseHandler do
  def send_nil(socket) do
    IO.puts "sending nil"
    :gen_tcp.send socket, "$-1\r\n"
    socket
  end

  def send_val(socket, val) do
    val_bytes = val |> String.length |> Integer.to_string
    msg = "$" <> val_bytes <> "\r\n" <> val <> "\r\n"
    IO.puts "sending val: #{msg}"
    :gen_tcp.send socket, msg
    socket
  end

  def send_ok(socket) do
    IO.puts "sending ok"
    :gen_tcp.send socket, "+OK\r\n"
    socket
  end

  def send_integer_response(socket, 0) do
    :gen_tcp.send socket, ":0\r\n"
  end

  def send_integer_response(socket, 1) do
    :gen_tcp.send socket, ":1\r\n"
  end
end

