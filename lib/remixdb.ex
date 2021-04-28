defmodule Remixdb do
  use Application

  def start(_type, _args) do
    :io.format("~p, type: ~p, args: ~p ~n", [__MODULE__, _type, _args])
    Remixdb.Supervisor.start_link([])
  end
end
