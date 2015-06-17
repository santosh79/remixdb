defmodule Remixdb do
  defmodule Server do
    def start do
      server_pid = spawn fn -> loop() end
      Process.register server_pid, :remixdb_server
    end

    def get_connection do
    end

    def set(from, key, val) do
      server_pid = Process.whereis :remixdb_server
      send server_pid, {from, {:set, key, val}}
    end

    def get(from, key) do
      send from, "bar"
    end

    def stop(from) do
      server_pid = Process.whereis :remixdb_server
      send server_pid, {from, :die}
    end

    def loop do
      receive do
        {from, {:set, key, val}} ->
          send from, :ok
          loop()
        {from, :die} ->
          send from, :ok
          Process.unregister :remixdb_server
          Process.exit self, "asked to die by #{inspect from}"
      end
    end
  end
end
