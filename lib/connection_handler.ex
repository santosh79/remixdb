defmodule Remixdb.ClientHander do
  def start do
    spawn Remixdb.ClientHander, :loop, []
  end

  def loop do
    loop []
  end

  defp loop(clients) do
    receive do 
      {:new_client, client} ->
        IO.puts "connection handler: got new connection"
        Remixdb.Client.start client
        loop clients ++ [client]
      {_} -> :void
    end
  end
end
