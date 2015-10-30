defmodule Remixdb.KeyHandler do
  def init do
    nil
  end

  def exists?(key) do
    Remixdb.SimpleServer.rpc :remixdb_key_handler, {:exists, key}
  end

  def get(key) do
    Remixdb.SimpleServer.rpc :remixdb_key_handler, {:get, key}
  end

  def set(key, val) do
    Remixdb.SimpleServer.rpc :remixdb_key_handler, {:set, key, val}
  end

  def handle(request, nil) do
    case request do
      {:exists, key} ->
        val = !!(key |> get_key_pid)
        {val, nil}
      {:get, key} ->
        val = case(key |> get_key_pid) do
          nil -> nil
          key_pid -> 
            key |> get_key_name |>
            Remixdb.String.get(key)
        end
        {val, nil}
      {:set, key, val} ->
        key_name = key |> get_key_name
        key_pid = case (key |> get_key_pid) do
          nil ->
            Remixdb.SimpleServer.start key_name, Remixdb.String
          pid -> pid
        end
        Remixdb.String.set key_name, key, val
        {:ok, nil}
    end
  end


  defp get_key_pid(key) do
    key |> get_key_name |> Process.whereis
  end

  defp get_key_name(key) do
    ("remixdb_string|" <> key) |> String.to_atom
  end
end

