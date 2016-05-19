defmodule Remixdb.Misc do
  def pmap(items, func) do
    tasks = items |>
    Enum.map(fn(item) ->
      Task.async(fn -> func.(item) end)
    end) |> Enum.map(fn(task) ->
      Task.await(task)
    end)
  end
end

