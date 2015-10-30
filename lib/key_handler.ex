defmodule Remixdb.KeyHandler do
  def start do
    pid = spawn Remixdb.KeyHandler, :loop, []
    Process.register pid, :remixdb_key_handler
    pid
  end

  def stop do
    Remixdb.ProcessCleaner.stop :remixdb_key_handler
  end

  def loop do
    receive do
      {sender, {:set, [key, val]}} ->
        key_name = key |> get_key_name
        key_pid = case (key |> get_key_pid) do
          nil ->
            Remixdb.SimpleServer.start key_name, Remixdb.String
          pid -> pid
        end
        Remixdb.String.set key_name, key, val
        send sender, {self(), :ok}
      {sender, {:exists, key}} ->
        val = !!(key |> get_key_pid)
        send sender, {self(), val}
      {sender, {:get, key}} ->
        val = case(key |> get_key_pid) do
          nil -> nil
          key_pid -> 
            key |> get_key_name |>
            Remixdb.String.get(key)
        end
        send sender, {self(), val}
    end
    loop
  end

  def wait_for_response do
    key_handler = get_key_handler
    receive do
      {^key_handler, val} -> val
    end
  end

  def set(key, val) do
    key_handler = get_key_handler
    send key_handler, {self(), {:set, [key, val]}}
    val = case wait_for_response do
      :error -> :error
      val -> val
    end
    val
  end

  def get(key) do
    key_handler = get_key_handler
    send key_handler, {self(), {:get, key}}
    case wait_for_response do
      :error -> :error
      val -> val
    end
  end

  def exists?(key) do
    key_handler = get_key_handler
    send key_handler, {self(), {:exists, key}}
    case wait_for_response do
      :error -> :error
      val -> val
    end
  end

  def get_key_pid(key) do
    key |> get_key_name |> Process.whereis
  end

  defp get_key_name(key) do
    ("remixdb_string|" <> key) |> String.to_atom
  end

  defp get_key_handler do
    pid = Process.whereis :remixdb_key_handler
    pid
  end
end

