defmodule Remixdb.TcpServer do

  def start do
    port = 6379
    {:ok, socket} = :gen_tcp.listen(port, [:binary, packet: :raw, active: false, reuseaddr: true])
    IO.puts "Accepting connections on port: #{port}"
    accept_loop socket
  end

  def handle_info(_, state), do: {:noreply, state}
  defp accept_loop(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    spawn(fn ->
      Remixdb.Client.start_link client
    end)
    accept_loop socket
  end
end

