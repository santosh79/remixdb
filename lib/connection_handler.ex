defmodule Remixdb.ClientHander do
  def init do
    []
  end

  def new_client(name, client) do
    Remixdb.SimpleServer.rpc name, {:new_client, client}
  end

  def handle(request, state) do
    case request do
      {:new_client, client} ->
        IO.puts "connection handler: got new connection"
        Remixdb.Client.start client
        {:ok, state ++ [client]}
      {_} -> :void
    end
  end
end

