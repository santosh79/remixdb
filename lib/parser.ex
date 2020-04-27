defmodule Remixdb.Parser do
  def read_command(pid) do
    Remixdb.Parsers.RedisParser.read_command(pid)
  end
end
