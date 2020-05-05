defmodule Remixdb.TcpServer do

  def start(port \\ 6379) do
    {:ok, socket} = :gen_tcp.listen(port, [:binary, packet: :raw, active: false, reuseaddr: true, backlog: 1_000])
    IO.puts "Accepting connections on port: #{port}"
    accept_loop socket
  end

  def handle_info(_, state), do: {:noreply, state}
  defp accept_loop(socket) do
    {:ok, client_sock} = :gen_tcp.accept(socket)
    client_mod = case Application.get_env(:remixdb, :client) do
      nil -> Remixdb.RedisClient
      mod -> mod
    end
    spawn_link(client_mod, :start_link, [client_sock])
    accept_loop socket
  end
end

