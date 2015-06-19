defmodule Remixdb do
  defmodule Server do
    def start do
      {:ok, server_pid} = Task.start(fn -> loop(HashDict.new) end)
      Process.register server_pid, :remixdb_server
    end

    def get_connection do
    end

    def set(from, key, val) do
      server_pid = Process.whereis :remixdb_server
      send server_pid, {from, {:set, key, val}}
    end

    def get(from, key) do
      server_pid = Process.whereis :remixdb_server
      send server_pid, {from, {:get, key}}
    end

    def stop(from) do
      server_pid = Process.whereis :remixdb_server
      send server_pid, {from, :die}
    end

    def loop(map) do
      receive do
        {from, {:set, key, val}} ->
          new_map = Dict.put(map, key, val)
          send from, :ok
          loop new_map
        {from, {:get, key}} ->
          val = Dict.get(map, key)
          send from, val
          loop map
        {from, :die} ->
          Task.start fn ->
            :timer.sleep 50
            send from, :ok
          end
          Process.unregister :remixdb_server
          Process.exit self, "asked to die by #{inspect from}"
      end
    end
  end
end
