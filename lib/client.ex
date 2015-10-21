defmodule Remixdb.Client do
  def start(socket) do
    spawn Remixdb.Client, :loop, [socket]
  end

  def loop(socket) do
    serve socket
  end

  defp serve(socket) do
    serve socket, 0
  end

  defp serve(socket, num) do
    IO.puts "num: #{num}"

    socket
    |> read_line()

    case num do
      6 -> send_ok(socket)
      11 -> send_bar(socket)
      _  -> :void
    end
    serve socket, (num + 1)
  end

  defp read_line(socket) do
    val = :gen_tcp.recv(socket, 0)
    case val do
      {:ok, data} ->
        IO.puts "data: #{data}"
        data
      {:error, _} ->
        IO.puts "client closed the connection"
    end
  end

  defp send_ok(socket) do
    IO.puts "sending ok"
    :gen_tcp.send socket, "+OK\r\n"
  end

  defp send_bar(socket) do
    IO.puts "sending bar"
    str = "$3\r\nBARr\r\n"
    :gen_tcp.send socket, "$3\r\nBAR\r\n"
  end

  defp write_line(line, socket) do
    :gen_tcp.send socket, line
  end
end

