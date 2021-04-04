defmodule Remixdb.TcpServer do

  def start(port \\ 6379, client_mod \\ Remixdb.RedisClient) do
    {:ok, socket} = :gen_tcp.listen(port, [:binary, packet: :raw, active: false, reuseaddr: true, backlog: 1_000])
    IO.puts "Accepting connections on port: #{port}"
    accept_loop socket, client_mod
  end

  def handle_info(_, state), do: {:noreply, state}
  defp accept_loop(socket, client_mod) do
    # Wait for a connection
    {:ok, client_sock} = :gen_tcp.accept(socket)

    spawn_link(client_mod, :start_link, [client_sock])

    accept_loop socket, client_mod
  end
end

