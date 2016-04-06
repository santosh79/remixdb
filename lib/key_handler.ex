defmodule Remixdb.KeyHandler do
  def init do
    Process.flag :trap_exit, true
    %{}
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

  def append(key, val) do
    Remixdb.SimpleServer.rpc :remixdb_key_handler, {:append, key, val}
  end

  def dbsize do
    Remixdb.SimpleServer.rpc :remixdb_key_handler, :dbsize
  end

  def flushall do
    Remixdb.SimpleServer.rpc :remixdb_key_handler, :flushall
  end

  def handle(request, state) do
    case request do
      :flushall ->
        state |> Dict.values |> Enum.each(fn(pid) ->
          Process.exit(pid, :kill)
        end)
        {:ok, %{}}
      :dbsize ->
        count = state |> Dict.keys |> Enum.count
        {count, state}
      {:exists, key} ->
        val = !!(key |> get_key_pid)
        {val, state}
      {:get, key} ->
        val = case(key |> get_key_pid) do
          nil -> nil
          key_pid -> 
            key |> get_key_name |>
            Remixdb.String.get(key)
        end
        {val, state}
      {:append, key, val} ->
        key_name = key |> get_key_name
        new_val = Remixdb.String.append key_name, key, val
        string_length = new_val |> String.length
        {string_length, state}
      {:set, key, val} ->
        key_name = key |> get_key_name
        new_key = false
        key_pid = case (key |> get_key_pid) do
          nil ->
            new_key = true
            Remixdb.SimpleServer.start key_name, Remixdb.String
            Process.whereis key_name
          pid -> pid
        end
        Remixdb.String.set key_name, key, val
        new_state = case new_key do
          true ->
            Dict.put(state, key_name, key_pid)
          false -> state
        end
        {:ok, new_state}
    end
  end


  defp get_key_pid(key) do
    key |> get_key_name |> Process.whereis
  end

  defp get_key_name(key) do
    ("remixdb_string|" <> key) |> String.to_atom
  end
end

