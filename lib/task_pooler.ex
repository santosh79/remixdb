defmodule Remixdb.TaskPooler do
  def async(func) do
    Task.async(func)
  end

  def await(task_id) do
    Task.await(task_id)
  end
end
