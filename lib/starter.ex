defmodule Remixdb.Starter do
  def main(_args) do
    Application.start :remixdb
    receive do
      after  :infinity -> true
    end
  end
end
