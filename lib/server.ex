defmodule Remixdb.Server do
  def start do
    spawn_link(fn ->
      Remixdb.TcpServer.start_link
      Remixdb.KeyHandler.start_link
      receive  do
        :shutdown ->
          IO.puts "shutting down"
          true
      end
    end)
  end

  # def terminate(:normal, _) do
  #   IO.puts "Remixdb.Server terminating"
  #   :ok
  # end
end

