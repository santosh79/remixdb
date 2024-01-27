defmodule Remixdb.Datastructures.Supervisor do
  use Supervisor

  @name :remixdb_datastructures_supervisor

  def start_link(_args) do
    Supervisor.start_link(__MODULE__, :ok, name: @name)
  end

  def init(:ok) do
    children = [
      # Remixdb.String,
      {Remixdb.String.ShardManager, []},
      Remixdb.Hash,
      Remixdb.Set,
      Remixdb.List
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
