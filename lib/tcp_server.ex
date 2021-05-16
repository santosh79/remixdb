defmodule Remixdb.TcpServer do

  def start(port \\ 6379, client_mod \\ Remixdb.RedisClient) do
    {:ok, socket} = :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true, backlog: 1_000])
    :io.format("~p at port: ~p ~n", [__MODULE__, port])
    accept_loop socket, client_mod
  end

  def handle_info({'DOWN', ref, :process, _pid, _reason}, state) do
    updated_state = state |> Map.delete(ref)
    {:noreply, updated_state}
  end

  def handle_info(_, state), do: {:noreply, state}

  defp accept_loop(socket, client_mod, state \\ %{}) do
    # Wait for a connection
    {:ok, client_sock} = :gen_tcp.accept(socket)

    {pid, mon} = :erlang.spawn_monitor(fn ->
      :erlang.apply client_mod, :start_link, [client_sock]
      # receive do
      # end
    end)
    updated_state = state |> Map.put(mon, pid)
    accept_loop socket, client_mod, updated_state
  end
end

