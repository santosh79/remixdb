defmodule Mix.Tasks.Remixdb do
  use Mix.Task
  def run(_) do
    Mix.Task.run "compile"
    # Remixdb.Server.start_link
  end
end

