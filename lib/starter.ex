defmodule Remixdb.Starter do
  def main(_args) do
    Remixdb.Supervisor.start_link([])
    receive do
      after  :infinity -> true
    end
  end
end
