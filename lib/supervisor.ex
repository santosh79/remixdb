defmodule Remixdb.Supervisor do
  use Supervisor

  @name :remixdb_supervisor

  def start_link(_args) do
    Supervisor.start_link __MODULE__, :ok, name: @name
  end

  def init(:ok) do
    children = [
      Remixdb.Datastructures.Supervisor,
      Remixdb.TcpServer
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end
end

