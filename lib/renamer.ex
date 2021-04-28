defmodule Remixdb.Renamer do
  def rename(state, old_name, new_name) when is_map(state) do
    case Map.get(state, old_name, nil) do
      nil -> {false, state}
      old_val ->
        new_state = state |> Map.put(new_name, old_val) |> Map.delete(old_name)
        {true, new_state}
    end
  end
end
