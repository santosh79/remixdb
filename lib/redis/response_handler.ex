defmodule Remixdb.Redis.ResponseHandler do
  def send_response(socket, nil) do
    :gen_tcp.send socket, "$-1\r\n"
    socket
  end

  def send_response(socket, :undefined) do
    send_response socket, nil
  end

  def send_response(socket, {:error, val}) when is_bitstring(val) do
    msg = "-" <> val <> "\r\n"
    :gen_tcp.send socket, msg
    socket
  end

  def send_response(socket, val) when is_bitstring(val) do
    val_bytes = val |> byte_size |> Integer.to_string
    msg = "$" <> val_bytes <> "\r\n" <> val <> "\r\n"
    :gen_tcp.send socket, msg
    socket
  end

  def send_response(socket, num) when is_integer(num) do
    response = ":" <> (num |> Integer.to_string) <> "\r\n"
    :gen_tcp.send socket, response
    socket
  end

  def send_response(socket, val) when is_boolean(val) do
    case val do
      true -> send_response(socket, 1)
      _ -> send_response(socket, 0)
    end
  end

  def send_response(socket, val) when is_list(val) do
    header = "*" <> (val |> Enum.count |> Integer.to_string) <> "\r\n"
    :gen_tcp.send socket, header

    Enum.each(val, fn(el) -> send_response(socket, el) end)
    socket
  end

  def send_response(socket, :ok) do
    socket |> send_ok
  end

  def send_ok(socket) do
    :gen_tcp.send socket, "+OK\r\n"
    socket
  end

end

