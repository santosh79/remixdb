defmodule Remixdb do
  use Application

  def start(_type, _args) do
    Remixdb.Supervisor.start_link([])
  end
end
