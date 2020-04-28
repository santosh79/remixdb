defmodule Remixdb.Supervisor do
  use Supervisor

  @name :remixdb_supervisor

  def start_link(_args) do
    Supervisor.start_link __MODULE__, :ok, name: @name
  end

  def init(:ok) do
    children = [
      Remixdb.Server,
      Remixdb.KeyHandler
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end
end

