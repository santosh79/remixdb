defmodule Remixdb.ProcessCleaner do
  def stop(name) do
    case (Process.whereis name) do
      nil -> :void
      pid -> Process.exit(pid, :kill)
    end
  end
end

