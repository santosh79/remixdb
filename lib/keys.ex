defmodule Remixdb.Keys do
  def popped_out?(items, pid) when is_pid(pid) do
    if ((items |> Enum.count) <= 0) do
      GenServer.cast pid, :stop
    end
  end
end
