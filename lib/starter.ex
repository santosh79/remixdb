defmodule Remixdb.Starter do
  def main(_args) do
    Remixdb.Server.start
    receive do
      after  :infinity -> true
    end
  end
end
