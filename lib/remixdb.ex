defmodule Remixdb do
  use Application

  def start(_type, _args) do
    Remixdb.Server.start_link
  end
end

